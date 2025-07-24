const Booking = require('../models/Booking');
const Place = require('../models/Place');

// Tourist: Create a new booking
exports.createBooking = async (req, res) => {
    const { placeId, bookingDate, numberOfPeople } = req.body;
    const userId = req.user._id; // From auth middleware

    try {
        const place = await Place.findById(placeId);

        if (!place) {
            return res.status(404).json({ message: 'Place not found' });
        }

        // Basic availability check (can be more sophisticated)
        const requestedDate = new Date(bookingDate);
        const isDateAvailable = place.availableDates.some(date =>
            date.toDateString() === requestedDate.toDateString()
        );

        if (!isDateAvailable) {
            return res.status(400).json({ message: 'Selected date is not available for this place.' });
        }

        if (numberOfPeople > place.maxCapacity) {
            return res.status(400).json({ message: `Number of people exceeds maximum capacity of ${place.maxCapacity}.` });
        }

        const totalPrice = place.pricePerPerson * numberOfPeople;

        const booking = new Booking({
            user: userId,
            place: placeId,
            bookingDate: requestedDate,
            numberOfPeople,
            totalPrice,
            status: 'pending', // Initial status
            paymentStatus: 'pending' // Initial payment status
        });

        const createdBooking = await booking.save();
        res.status(201).json(createdBooking);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Tourist: Get user's bookings
exports.getUserBookings = async (req, res) => {
    try {
        const bookings = await Booking.find({ user: req.user._id }).populate('place', 'name location pricePerPerson');
        res.json(bookings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Get all bookings
exports.getAllBookings = async (req, res) => {
    try {
        const bookings = await Booking.find({}).populate('user', 'username email').populate('place', 'name location');
        res.json(bookings);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Admin: Update booking status
exports.updateBookingStatus = async (req, res) => {
    const { status, paymentStatus } = req.body;

    try {
        const booking = await Booking.findById(req.params.id);

        if (booking) {
            booking.status = status || booking.status;
            booking.paymentStatus = paymentStatus || booking.paymentStatus;

            const updatedBooking = await booking.save();
            res.json(updatedBooking);
        } else {
            res.status(404).json({ message: 'Booking not found' });
        }
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Placeholder for Hormuud payment initiation
exports.initiateHormuudPayment = async (req, res) => {
    const { bookingId } = req.body;

    try {
        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        // --- This is where you would integrate with Hormuud API ---
        // Example: Call Hormuud API with booking.totalPrice and other details
        // const paymentResponse = await axios.post('HORMUUD_API_ENDPOINT', {
        //     amount: booking.totalPrice,
        //     currency: 'USD', // Or SOS
        //     callbackUrl: 'YOUR_CALLBACK_URL',
        //     // ... other required parameters
        // });

        // If payment initiation is successful, update paymentStatus to 'pending' (if not already)
        // and return a payment URL or confirmation.
        // For now, we'll simulate success.
        booking.paymentStatus = 'pending'; // Or 'initiated'
        await booking.save();

        res.json({
            message: 'Hormuud payment initiated successfully (simulated).',
            paymentUrl: 'https://example.com/hormuud-payment-gateway-redirect' // Placeholder URL
        });

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Placeholder for Hormuud payment callback/webhook
exports.handleHormuudCallback = async (req, res) => {
    // This endpoint would be called by Hormuud after a payment attempt.
    // You would verify the payment status and update your booking.

    const { transactionId, status, bookingId } = req.body; // Example parameters from Hormuud callback

    try {
        const booking = await Booking.findById(bookingId);

        if (!booking) {
            return res.status(404).json({ message: 'Booking not found' });
        }

        if (status === 'success') {
            booking.paymentStatus = 'paid';
            booking.status = 'confirmed'; // Confirm booking after successful payment
            await booking.save();
            res.status(200).json({ message: 'Payment successful and booking confirmed.' });
        } else {
            booking.paymentStatus = 'failed';
            await booking.save();
            res.status(400).json({ message: 'Payment failed.' });
        }

    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};