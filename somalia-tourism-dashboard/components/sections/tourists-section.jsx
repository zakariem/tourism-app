"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Search, Plus, MoreHorizontal, Eye, Edit, Trash2, Users, UserCheck, UserX } from "lucide-react"

const tourists = [
  {
    id: "T001",
    name: "Ahmed Hassan",
    email: "ahmed.hassan@email.com",
    phone: "+252 61 234 5678",
    nationality: "Somalia",
    status: "active",
    totalBookings: 5,
    totalSpent: "$2,450",
    joinDate: "2024-01-15",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "T002",
    name: "Fatima Ali",
    email: "fatima.ali@email.com",
    phone: "+252 61 345 6789",
    nationality: "Ethiopia",
    status: "active",
    totalBookings: 3,
    totalSpent: "$1,280",
    joinDate: "2024-01-20",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "T003",
    name: "Omar Mohamed",
    email: "omar.mohamed@email.com",
    phone: "+252 61 456 7890",
    nationality: "Kenya",
    status: "inactive",
    totalBookings: 2,
    totalSpent: "$890",
    joinDate: "2024-02-01",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "T004",
    name: "Amina Abdi",
    email: "amina.abdi@email.com",
    phone: "+252 61 567 8901",
    nationality: "Djibouti",
    status: "active",
    totalBookings: 7,
    totalSpent: "$3,120",
    joinDate: "2023-12-10",
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "T005",
    name: "Hassan Ibrahim",
    email: "hassan.ibrahim@email.com",
    phone: "+252 61 678 9012",
    nationality: "Somalia",
    status: "active",
    totalBookings: 4,
    totalSpent: "$1,890",
    joinDate: "2024-01-25",
    avatar: "/placeholder.svg?height=40&width=40",
  },
]

const stats = [
  {
    title: "Total Tourists",
    value: "2,847",
    icon: Users,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Active Tourists",
    value: "2,234",
    icon: UserCheck,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Inactive Tourists",
    value: "613",
    icon: UserX,
    color: "text-red-600",
    bgColor: "bg-red-100",
  },
]

export function TouristsSection() {
  const [searchTerm, setSearchTerm] = useState("")

  const filteredTourists = tourists.filter(
    (tourist) =>
      tourist.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tourist.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      tourist.nationality.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Tourist Management</h1>
          <p className="text-gray-600 mt-1">Manage and monitor tourist accounts</p>
        </div>
        <Button className="bg-gradient-to-r from-blue-600 to-orange-500 hover:from-blue-700 hover:to-orange-600">
          <Plus className="h-4 w-4 mr-2" />
          Add New Tourist
        </Button>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
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

      {/* Search and Filters */}
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
          <div className="flex items-center justify-between">
            <CardTitle>Tourist Directory</CardTitle>
            <div className="flex items-center gap-4">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
                <Input
                  placeholder="Search tourists..."
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
                <TableHead>Tourist</TableHead>
                <TableHead>Contact</TableHead>
                <TableHead>Nationality</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Bookings</TableHead>
                <TableHead>Total Spent</TableHead>
                <TableHead>Join Date</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filteredTourists.map((tourist) => (
                <TableRow key={tourist.id} className="hover:bg-gray-50">
                  <TableCell>
                    <div className="flex items-center gap-3">
                      <Avatar className="h-10 w-10">
                        <AvatarImage src={tourist.avatar || "/placeholder.svg"} />
                        <AvatarFallback className="bg-gradient-to-r from-blue-500 to-orange-500 text-white">
                          {tourist.name
                            .split(" ")
                            .map((n) => n[0])
                            .join("")}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="font-medium text-gray-900">{tourist.name}</p>
                        <p className="text-sm text-gray-500">{tourist.id}</p>
                      </div>
                    </div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <p className="text-sm text-gray-900">{tourist.email}</p>
                      <p className="text-sm text-gray-500">{tourist.phone}</p>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline" className="border-blue-200 text-blue-700">
                      {tourist.nationality}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <Badge
                      variant={tourist.status === "active" ? "default" : "secondary"}
                      className={
                        tourist.status === "active"
                          ? "bg-green-100 text-green-800 hover:bg-green-100"
                          : "bg-red-100 text-red-800 hover:bg-red-100"
                      }
                    >
                      {tourist.status}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <span className="font-medium">{tourist.totalBookings}</span>
                  </TableCell>
                  <TableCell>
                    <span className="font-medium text-green-600">{tourist.totalSpent}</span>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm text-gray-600">{tourist.joinDate}</span>
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
                          Edit Tourist
                        </DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">
                          <Trash2 className="h-4 w-4 mr-2" />
                          Delete Tourist
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  )
}
