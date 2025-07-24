const express = require('express');
const { createBooking, getUserBookings, getAllBookings, updateBookingStatus, initiateHormuudPayment, handleHormuudCallback } = require('../controllers/bookingController');
const { protect, authorizeRoles } = require('../middleware/authMiddleware');
const router = express.Router();

// Tourist routes
router.post('/', protect, authorizeRoles('tourist'), createBooking);
router.get('/my-bookings', protect, authorizeRoles('tourist'), getUserBookings);
router.post('/initiate-payment', protect, authorizeRoles('tourist'), initiateHormuudPayment); // Tourist initiates payment

// Admin routes
router.get('/', protect, authorizeRoles('admin'), getAllBookings);
router.put('/:id/status', protect, authorizeRoles('admin'), updateBookingStatus);

// Public route for payment gateway callback (no auth needed as it's from Hormuud)
router.post('/payment-callback', handleHormuudCallback);

module.exports = router;