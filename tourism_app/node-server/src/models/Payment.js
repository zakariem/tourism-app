const mongoose = require('mongoose');
const validator = require('validator');

// Payment model for Tourism app integrating WaafiPay
const PaymentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User reference is required"]
    },
    userFullName: {
      type: String,
      required: [true, "User's full name is required"],
      trim: true,
      minlength: [3, "Full name must be at least 3 characters"],
      maxlength: [100, "Full name must not exceed 100 characters"]
    },
    userAccountNo: {
      type: String,
      required: [true, "User's mobile wallet number is required"],
      validate: {
        validator: function (v) {
          // Validate international phone number format
          return validator.isMobilePhone(v, 'any', { strictMode: false });
        },
        message: props => `${props.value} is not a valid phone number!`
      }
    },
    placeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Place",
      required: [true, "Place reference is required"]
    },
    placeName: {
      type: String,
      required: [true, "Place name is required"],
      trim: true
    },
    bookingDate: {
      type: Date,
      required: [true, "Booking date is required"]
    },
    timeSlot: {
      type: String,
      required: [true, "Time slot is required"]
    },
    visitorCount: {
      type: Number,
      required: [true, "Visitor count is required"],
      min: [1, "Visitor count must be at least 1"]
    },
    pricePerPerson: {
      type: Number,
      required: [true, "Price per person is required"],
      min: [0, "Price per person cannot be negative"]
    },
    totalAmount: {
      type: Number,
      required: [true, "Total amount is required"],
      validate: {
        validator: function (v) {
          return v > 0;
        },
        message: props => `Total amount must be greater than zero, got ${props.value}`
      }
    },
    actualPaidAmount: {
      type: Number,
      required: [true, "Actual paid amount is required"],
      default: 0.01, // Test amount for WaafiPay
      validate: {
        validator: function (v) {
          return v > 0;
        },
        message: props => `Actual paid amount must be greater than zero, got ${props.value}`
      }
    },
    currency: {
      type: String,
      default: "USD",
      uppercase: true,
      validate: {
        validator: function (v) {
          // ISO 4217 currency code validation: 3 uppercase letters
          return validator.isCurrency(`1 ${v}`) || /^[A-Z]{3}$/.test(v);
        },
        message: props => `${props.value} is not a valid currency code` 
      }
    },
    paymentMethod: {
      type: String,
      default: "mwallet_account",
      enum: ["mwallet_account", "CREDIT_CARD", "BANK_TRANSFER"],
      description: "Payment method used"
    },
    contactInfo: {
      email: { type: String },
      phone: { type: String }
    },
    waafiResponse: {
      referenceId: { type: String, description: "Reference ID returned by WaafiPay" },
      transactionId: { type: String, description: "Transaction ID returned by WaafiPay" },
      issuerTransactionId: { type: String, description: "Issuer transaction ID from WaafiPay" },
      state: { type: String, description: "Transaction state (e.g., APPROVED)" },
      responseCode: { type: String, description: "Response code returned by WaafiPay" },
      responseMsg: { type: String, description: "Response message from WaafiPay" },
      merchantCharges: { type: Number, description: "Fees charged by the merchant gateway" },
      txAmount: { type: Number, description: "Actual amount processed by WaafiPay" }
    },
    bookingStatus: {
      type: String,
      enum: ['pending', 'confirmed', 'cancelled', 'completed'],
      default: 'pending'
    },
    paidAt: {
      type: Date,
      default: Date.now,
      description: "Timestamp when the payment was made"
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Payment', PaymentSchema);