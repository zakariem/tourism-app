const express = require('express');
const router = express.Router();
const {
  createPayment,
  getPaymentHistory,
  getPaymentById,
  updatePaymentStatus
} = require('../controllers/paymentController');

// @route   POST /api/payments
// @desc    Create a new payment for place booking
// @access  Public (should be protected in production)
router.post('/', createPayment);

// @route   GET /api/payments/history/:userId
// @desc    Get payment history for a specific user
// @access  Public (should be protected in production)
router.get('/history/:userId', getPaymentHistory);

// @route   GET /api/payments/:paymentId
// @desc    Get payment details by ID
// @access  Public (should be protected in production)
router.get('/:paymentId', getPaymentById);

// @route   PUT /api/payments/:paymentId/status
// @desc    Update payment status
// @access  Public (should be protected in production)
router.put('/:paymentId/status', updatePaymentStatus);

module.exports = router;