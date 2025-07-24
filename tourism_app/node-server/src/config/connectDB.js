import mongoose from "mongoose";
import colors from "colors";

export const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log(colors.yellow(`MongoDB is connected: ${mongoose.connection.host}`));
  } catch (error) {
    console.log("Error connecting to MongoDB", error);
    process.exit(1);
  }
};

// export default connectDB;
