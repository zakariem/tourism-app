"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Search, Plus, MoreHorizontal, Eye, Edit, Trash2, Calendar, CheckCircle, Clock, XCircle } from "lucide-react"

const bookings = [
  {
    id: "BK001",
    tourist: "Ahmed Hassan",
    destination: "Mogadishu Beach Resort",
    checkIn: "2024-02-15",
    checkOut: "2024-02-18",
    guests: 2,
    amount: "$450",
    status: "confirmed",
    paymentStatus: "paid",
    bookingDate: "2024-01-20",
  },
  {
    id: "BK002",
    tourist: "Fatima Ali",
    destination: "Berbera Historical Tour",
    checkIn: "2024-02-20",
    checkOut: "2024-02-22",
    guests: 1,
    amount: "$320",
    status: "pending",
    paymentStatus: "pending",
    bookingDate: "2024-02-01",
  },
  {
    id: "BK003",
    tourist: "Omar Mohamed",
    destination: "Hargeisa Cultural Experience",
    checkIn: "2024-02-25",
    checkOut: "2024-02-27",
    guests: 3,
    amount: "$280",
    status: "confirmed",
    paymentStatus: "paid",
    bookingDate: "2024-02-05",
  },
  {
    id: "BK004",
    tourist: "Amina Abdi",
    destination: "Bosaso Coastal Adventure",
    checkIn: "2024-03-01",
    checkOut: "2024-03-04",
    guests: 2,
    amount: "$380",
    status: "cancelled",
    paymentStatus: "refunded",
    bookingDate: "2024-01-28",
  },
  {
    id: "BK005",
    tourist: "Hassan Ibrahim",
    destination: "Kismayo Wildlife Safari",
    checkIn: "2024-03-05",
    checkOut: "2024-03-08",
    guests: 4,
    amount: "$620",
    status: "confirmed",
    paymentStatus: "paid",
    bookingDate: "2024-02-10",
  },
]

const stats = [
  {
    title: "Total Bookings",
    value: "1,234",
    icon: Calendar,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Confirmed",
    value: "987",
    icon: CheckCircle,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Pending",
    value: "156",
    icon: Clock,
    color: "text-yellow-600",
    bgColor: "bg-yellow-100",
  },
  {
    title: "Cancelled",
    value: "91",
    icon: XCircle,
    color: "text-red-600",
    bgColor: "bg-red-100",
  },
]

export function BookingsSection() {
  const [searchTerm, setSearchTerm] = useState("")

  const filteredBookings = bookings.filter(
    (booking) =>
      booking.tourist.toLowerCase().includes(searchTerm.toLowerCase()) ||
      booking.destination.toLowerCase().includes(searchTerm.toLowerCase()) ||
      booking.id.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const getStatusBadge = (status) => {
    const statusConfig = {
      confirmed: { color: "bg-green-100 text-green-800 hover:bg-green-100", label: "Confirmed" },
      pending: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100", label: "Pending" },
      cancelled: { color: "bg-red-100 text-red-800 hover:bg-red-100", label: "Cancelled" },
    }
    return statusConfig[status] || statusConfig.pending
  }

  const getPaymentBadge = (status) => {
    const statusConfig = {
      paid: { color: "bg-green-100 text-green-800 hover:bg-green-100", label: "Paid" },
      pending: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100", label: "Pending" },
      refunded: { color: "bg-blue-100 text-blue-800 hover:bg-blue-100", label: "Refunded" },
    }
    return statusConfig[status] || statusConfig.pending
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Booking Management</h1>
          <p className="text-gray-600 mt-1">Track and manage all tourist bookings</p>
        </div>
        <Button className="bg-gradient-to-r from-blue-600 to-orange-500 hover:from-blue-700 hover:to-orange-600">
          <Plus className="h-4 w-4 mr-2" />
          New Booking
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <Card key={index} className="border-0 shadow-lg">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <stat.icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Bookings Table */}
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
          <div className="flex items-center justify-between">
            <CardTitle>All Bookings</CardTitle>
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="Search bookings..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="pl-10 w-64"
                />
              </div>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-0">
          <Table>
            <TableHeader>
              <TableRow className="bg-gray-50">
                <TableHead>Booking ID</TableHead>
                <TableHead>Tourist</TableHead>
                <TableHead>Destination</TableHead>
                <TableHead>Check-in</TableHead>
                <TableHead>Check-out</TableHead>
                <TableHead>Guests</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Payment</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredBookings.map((booking) => {
                const statusBadge = getStatusBadge(booking.status)
                const paymentBadge = getPaymentBadge(booking.paymentStatus)

                return (
                  <TableRow key={booking.id} className="hover:bg-gray-50">
                    <TableCell>
                      <span className="font-medium text-blue-600">{booking.id}</span>
                    </TableCell>
                    <TableCell>
                      <span className="font-medium text-gray-900">{booking.tourist}</span>
                    </TableCell>
                    <TableCell>
                      <span className="text-gray-900">{booking.destination}</span>
                    </TableCell>
                    <TableCell>
                      <span className="text-sm text-gray-600">{booking.checkIn}</span>
                    </TableCell>
                    <TableCell>
                      <span className="text-sm text-gray-600">{booking.checkOut}</span>
                    </TableCell>
                    <TableCell>
                      <span className="font-medium">{booking.guests}</span>
                    </TableCell>
                    <TableCell>
                      <span className="font-medium text-green-600">{booking.amount}</span>
                    </TableCell>
                    <TableCell>
                      <Badge className={statusBadge.color}>{statusBadge.label}</Badge>
                    </TableCell>
                    <TableCell>
                      <Badge className={paymentBadge.color}>{paymentBadge.label}</Badge>
                    </TableCell>
                    <TableCell className="text-right">
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="sm">
                            <MoreHorizontal className="h-4 w-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem>
                            <Eye className="h-4 w-4 mr-2" />
                            View Details
                          </DropdownMenuItem>
                          <DropdownMenuItem>
                            <Edit className="h-4 w-4 mr-2" />
                            Edit Booking
                          </DropdownMenuItem>
                          <DropdownMenuItem className="text-red-600">
                            <Trash2 className="h-4 w-4 mr-2" />
                            Cancel Booking
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                )
              })}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
