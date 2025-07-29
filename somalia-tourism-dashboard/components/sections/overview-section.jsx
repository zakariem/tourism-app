"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Users, Calendar, MapPin, TrendingUp, DollarSign, Star, Building2 } from "lucide-react"

const stats = [
  {
    title: "Total Tourists",
    value: "2,847",
    change: "+12.5%",
    icon: Users,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Active Bookings",
    value: "1,234",
    change: "+8.2%",
    icon: Calendar,
    color: "text-orange-600",
    bgColor: "bg-orange-100",
  },
  {
    title: "Destinations",
    value: "45",
    change: "+3",
    icon: MapPin,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Revenue",
    value: "$124,500",
    change: "+15.3%",
    icon: DollarSign,
    color: "text-purple-600",
    bgColor: "bg-purple-100",
  },
]

const recentBookings = [
  {
    id: "BK001",
    tourist: "Ahmed Hassan",
    destination: "Mogadishu Beach Resort",
    date: "2024-02-15",
    status: "confirmed",
    amount: "$450",
  },
  {
    id: "BK002",
    tourist: "Fatima Ali",
    destination: "Berbera Historical Tour",
    date: "2024-02-18",
    status: "pending",
    amount: "$320",
  },
  {
    id: "BK003",
    tourist: "Omar Mohamed",
    destination: "Hargeisa Cultural Experience",
    date: "2024-02-20",
    status: "confirmed",
    amount: "$280",
  },
  {
    id: "BK004",
    tourist: "Amina Abdi",
    destination: "Bosaso Coastal Adventure",
    date: "2024-02-22",
    status: "confirmed",
    amount: "$380",
  },
]

const topDestinations = [
  {
    name: "Mogadishu Beach Resort",
    bookings: 156,
    rating: 4.8,
    revenue: "$45,200",
  },
  {
    name: "Berbera Historical Sites",
    bookings: 134,
    rating: 4.6,
    revenue: "$38,900",
  },
  {
    name: "Hargeisa Cultural Center",
    bookings: 98,
    rating: 4.7,
    revenue: "$28,400",
  },
  {
    name: "Bosaso Coastal Tours",
    bookings: 87,
    rating: 4.5,
    revenue: "$24,100",
  },
]

export function OverviewSection() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Dashboard Overview</h1>
          <p className="text-gray-600 mt-1">Welcome to Somalia Tourism Management System</p>
        </div>
        <div className="flex gap-3">
          <Button variant="outline" className="border-orange-200 text-orange-600 hover:bg-orange-50 bg-transparent">
            Export Report
          </Button>
          <Button className="bg-gradient-to-r from-blue-600 to-orange-500 hover:from-blue-700 hover:to-orange-600">
            Add New Booking
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <Card key={index} className="border-0 shadow-lg hover:shadow-xl transition-shadow">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
                  <p className="text-sm text-green-600 mt-1">{stat.change} from last month</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <stat.icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Bookings */}
        <Card className="border-0 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
            <CardTitle className="flex items-center gap-2">
              <Calendar className="h-5 w-5 text-blue-600" />
              Recent Bookings
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="space-y-0">
              {recentBookings.map((booking, index) => (
                <div
                  key={booking.id}
                  className="flex items-center justify-between p-4 border-b last:border-b-0 hover:bg-gray-50"
                >
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{booking.tourist}</p>
                    <p className="text-sm text-gray-600">{booking.destination}</p>
                    <p className="text-xs text-gray-500">{booking.date}</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-gray-900">{booking.amount}</p>
                    <Badge
                      variant={booking.status === "confirmed" ? "default" : "secondary"}
                      className={
                        booking.status === "confirmed"
                          ? "bg-green-100 text-green-800 hover:bg-green-100"
                          : "bg-yellow-100 text-yellow-800 hover:bg-yellow-100"
                      }
                    >
                      {booking.status}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Top Destinations */}
        <Card className="border-0 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-orange-50 to-blue-50 border-b">
            <CardTitle className="flex items-center gap-2">
              <MapPin className="h-5 w-5 text-orange-600" />
              Top Destinations
            </CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <div className="space-y-0">
              {topDestinations.map((destination, index) => (
                <div
                  key={index}
                  className="flex items-center justify-between p-4 border-b last:border-b-0 hover:bg-gray-50"
                >
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{destination.name}</p>
                    <div className="flex items-center gap-4 mt-1">
                      <span className="text-sm text-gray-600">{destination.bookings} bookings</span>
                      <div className="flex items-center gap-1">
                        <Star className="h-4 w-4 text-yellow-500 fill-current" />
                        <span className="text-sm text-gray-600">{destination.rating}</span>
                      </div>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-gray-900">{destination.revenue}</p>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
          <CardTitle>Quick Actions</CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Button variant="outline" className="h-20 flex-col gap-2 border-blue-200 hover:bg-blue-50 bg-transparent">
              <Users className="h-6 w-6 text-blue-600" />
              <span>Add Tourist</span>
            </Button>
            <Button
              variant="outline"
              className="h-20 flex-col gap-2 border-orange-200 hover:bg-orange-50 bg-transparent"
            >
              <MapPin className="h-6 w-6 text-orange-600" />
              <span>New Destination</span>
            </Button>
            <Button variant="outline" className="h-20 flex-col gap-2 border-green-200 hover:bg-green-50 bg-transparent">
              <Building2 className="h-6 w-6 text-green-600" />
              <span>Add Hotel</span>
            </Button>
            <Button
              variant="outline"
              className="h-20 flex-col gap-2 border-purple-200 hover:bg-purple-50 bg-transparent"
            >
              <TrendingUp className="h-6 w-6 text-purple-600" />
              <span>View Reports</span>
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
