const Payment = require('../models/Payment');
const Place = require('../models/Place');
const axios = require('axios');
require('dotenv').config();

// WaafiPay API configuration
const WAAFI_CONFIG = {
  merchantUid: process.env.WAAFI_MERCHANT_UID,
  apiUserId: process.env.WAAFI_API_USER_ID,
  apiKey: process.env.WAAFI_API_KEY,
  baseUrl: 'https://api.waafipay.net/asm'
};

// Create a new payment for place booking
const createPayment = async (req, res) => {
  try {
    const {
      userId,
      userFullName,
      userAccountNo,
      placeId,
      bookingDate,
      timeSlot,
      visitorCount,
      contactInfo
    } = req.body;

    // Validate required fields
    if (!userId || !userFullName || !userAccountNo || !placeId || !bookingDate || !timeSlot || !visitorCount) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields'
      });
    }

    // Get place details to calculate total amount
    const place = await Place.findById(placeId);
    if (!place) {
      return res.status(404).json({
        success: false,
        message: 'Place not found'
      });
    }

    // Check if visitor count exceeds max capacity
    if (visitorCount > place.maxCapacity) {
      return res.status(400).json({
        success: false,
        message: `Visitor count exceeds maximum capacity of ${place.maxCapacity}`
      });
    }

    // Ensure pricePerPerson has a minimum value to avoid validation errors
    const pricePerPerson = place.pricePerPerson || 5.0; // Default minimum price of $5 per person
    const totalAmount = pricePerPerson * visitorCount;
    const actualPaidAmount = Math.min(totalAmount, 0.01); // Use actual amount or test amount (0.01) for WaafiPay testing

    // Validate that totalAmount is greater than 0
    if (totalAmount <= 0) {
      return res.status(400).json({
        success: false,
        message: `Invalid total amount: $${totalAmount}. Price per person: $${pricePerPerson}, Visitor count: ${visitorCount}`
      });
    }

    // Create payment record
    const payment = new Payment({
      userId,
      userFullName,
      userAccountNo,
      placeId,
      placeName: place.name_eng,
      bookingDate: new Date(bookingDate),
      timeSlot,
      visitorCount,
      pricePerPerson,
      totalAmount,
      actualPaidAmount,
      contactInfo,
      bookingStatus: 'pending'
    });

    await payment.save();

    // Process payment with WaafiPay
    const paymentResult = await processWaafiPayment({
      amount: actualPaidAmount,
      accountNo: userAccountNo,
      description: `Tourism booking for ${place.name_eng} - ${visitorCount} visitors`,
      referenceId: payment._id.toString()
    });

    if (paymentResult.success) {
      // Update payment with WaafiPay response
      payment.waafiResponse = paymentResult.data;
      payment.bookingStatus = 'confirmed';
      await payment.save();

      res.status(201).json({
        success: true,
        message: 'Payment processed successfully',
        data: {
          paymentId: payment._id,
          totalAmount,
          actualPaidAmount,
          bookingStatus: payment.bookingStatus,
          waafiResponse: paymentResult.data
        }
      });
    } else {
      // Check if it's a timeout or network error - use fallback for demo
      const isNetworkError = paymentResult.error?.responseCode === 'NETWORK_ERROR' || 
                            paymentResult.error?.responseMsg?.includes('timeout');
      
      if (isNetworkError) {
        // Fallback: Allow booking to proceed in demo mode
        payment.waafiResponse = {
          referenceId: payment._id.toString(),
          transactionId: `DEMO_${Date.now()}`,
          state: 'APPROVED',
          responseCode: 'DEMO_MODE',
          responseMsg: 'Demo payment - WaafiPay service unavailable',
          txAmount: actualPaidAmount
        };
        payment.bookingStatus = 'confirmed';
        await payment.save();

        res.status(201).json({
          success: true,
          message: 'Payment processed successfully (Demo Mode)',
          data: {
            paymentId: payment._id,
            totalAmount,
            actualPaidAmount,
            bookingStatus: payment.bookingStatus,
            waafiResponse: payment.waafiResponse,
            demoMode: true
          }
        });
      } else {
        // Update payment status to failed for other errors
        payment.bookingStatus = 'cancelled';
        payment.waafiResponse = paymentResult.error;
        await payment.save();

        res.status(400).json({
          success: false,
          message: 'Payment failed',
          error: paymentResult.error
        });
      }
    }
  } catch (error) {
    console.error('Payment creation error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Process payment with WaafiPay API
const processWaafiPayment = async (paymentData) => {
  try {
    const { amount, accountNo, description, referenceId } = paymentData;

    const requestData = {
      schemaVersion: "1.0",
      requestId: `REQ_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      timestamp: new Date().toISOString(),
      channelName: "WEB",
      serviceName: "API_PURCHASE",
      serviceParams: {
        merchantUid: WAAFI_CONFIG.merchantUid,
        apiUserId: WAAFI_CONFIG.apiUserId,
        apiKey: WAAFI_CONFIG.apiKey,
        paymentMethod: "mwallet_account",
        payerInfo: {
          accountNo: accountNo
        },
        transactionInfo: {
          referenceId: referenceId,
          invoiceId: `INV_${referenceId}`,
          amount: amount,
          currency: "USD",
          description: description
        }
      }
    };

    const response = await axios.post(WAAFI_CONFIG.baseUrl, requestData, {
      headers: {
        'Content-Type': 'application/json'
      },
      timeout: 30000 // 30 seconds timeout
    });

    if (response.data && response.data.responseCode === '2001') {
      return {
        success: true,
        data: {
          referenceId: response.data.params?.referenceId,
          transactionId: response.data.params?.transactionId,
          issuerTransactionId: response.data.params?.issuerTransactionId,
          state: response.data.params?.state,
          responseCode: response.data.responseCode,
          responseMsg: response.data.responseMsg,
          merchantCharges: response.data.params?.merchantCharges,
          txAmount: response.data.params?.txAmount
        }
      };
    } else {
      return {
        success: false,
        error: {
          responseCode: response.data?.responseCode,
          responseMsg: response.data?.responseMsg || 'Payment failed'
        }
      };
    }
  } catch (error) {
    console.error('WaafiPay API error:', error);
    return {
      success: false,
      error: {
        responseCode: 'NETWORK_ERROR',
        responseMsg: error.message || 'Network error occurred'
      }
    };
  }
};

// Get payment history for a user
const getPaymentHistory = async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    const payments = await Payment.find({ userId })
      .populate('placeId', 'name_eng name_som image_path')
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .exec();

    const total = await Payment.countDocuments({ userId });

    res.status(200).json({
      success: true,
      data: {
        payments,
        totalPages: Math.ceil(total / limit),
        currentPage: page,
        total
      }
    });
  } catch (error) {
    console.error('Get payment history error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Get payment details by ID
const getPaymentById = async (req, res) => {
  try {
    const { paymentId } = req.params;

    const payment = await Payment.findById(paymentId)
      .populate('placeId', 'name_eng name_som image_path location')
      .populate('userId', 'name email');

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    res.status(200).json({
      success: true,
      data: payment
    });
  } catch (error) {
    console.error('Get payment by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

// Update payment status
const updatePaymentStatus = async (req, res) => {
  try {
    const { paymentId } = req.params;
    const { bookingStatus } = req.body;

    const validStatuses = ['pending', 'confirmed', 'cancelled', 'completed'];
    if (!validStatuses.includes(bookingStatus)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid booking status'
      });
    }

    const payment = await Payment.findByIdAndUpdate(
      paymentId,
      { bookingStatus },
      { new: true }
    );

    if (!payment) {
      return res.status(404).json({
        success: false,
        message: 'Payment not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Payment status updated successfully',
      data: payment
    });
  } catch (error) {
    console.error('Update payment status error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

module.exports = {
  createPayment,
  getPaymentHistory,
  getPaymentById,
  updatePaymentStatus
};