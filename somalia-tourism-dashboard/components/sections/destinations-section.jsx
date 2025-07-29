"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Search, Plus, MoreHorizontal, Eye, Edit, Trash2, MapPin, Star, DollarSign } from "lucide-react"
import { CreatePlaceModal } from "@/components/modals/create-place-modal" // Import CreatePlaceModal

const destinations = [
  {
    id: "D001",
    name: "Mogadishu Beach Resort",
    location: "Mogadishu, Banaadir",
    category: "Beach Resort",
    rating: 4.8,
    totalBookings: 156,
    revenue: "$45,200",
    status: "active",
    description: "Beautiful beachfront resort with modern amenities",
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "D002",
    name: "Berbera Historical Sites",
    location: "Berbera, Sahil",
    category: "Historical",
    rating: 4.6,
    totalBookings: 134,
    revenue: "$38,900",
    status: "active",
    description: "Explore ancient historical sites and Ottoman architecture",
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "D003",
    name: "Hargeisa Cultural Center",
    location: "Hargeisa, Maroodi Jeex",
    category: "Cultural",
    rating: 4.7,
    totalBookings: 98,
    revenue: "$28,400",
    status: "active",
    description: "Immerse yourself in Somali culture and traditions",
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "D004",
    name: "Bosaso Coastal Tours",
    location: "Bosaso, Bari",
    category: "Adventure",
    rating: 4.5,
    totalBookings: 87,
    revenue: "$24,100",
    status: "active",
    description: "Exciting coastal adventures and water sports",
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "D005",
    name: "Kismayo Wildlife Safari",
    location: "Kismayo, Jubbada Hoose",
    category: "Wildlife",
    rating: 4.4,
    totalBookings: 65,
    revenue: "$19,800",
    status: "maintenance",
    description: "Wildlife safari experience in natural reserves",
    image: "/placeholder.svg?height=200&width=300",
  },
]

const stats = [
  {
    title: "Total Destinations",
    value: "45",
    icon: MapPin,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Active Destinations",
    value: "38",
    icon: MapPin,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Average Rating",
    value: "4.6",
    icon: Star,
    color: "text-yellow-600",
    bgColor: "bg-yellow-100",
  },
  {
    title: "Total Revenue",
    value: "$156,400",
    icon: DollarSign,
    color: "text-purple-600",
    bgColor: "bg-purple-100",
  },
]

export function DestinationsSection() {
  const [searchTerm, setSearchTerm] = useState("")
  const [showCreateModal, setShowCreateModal] = useState(false)

  const filteredDestinations = destinations.filter(
    (destination) =>
      destination.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      destination.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
      destination.category.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const getStatusBadge = (status) => {
    const statusConfig = {
      active: { color: "bg-green-100 text-green-800 hover:bg-green-100", label: "Active" },
      maintenance: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100", label: "Maintenance" },
      inactive: { color: "bg-red-100 text-red-800 hover:bg-red-100", label: "Inactive" },
    }
    return statusConfig[status] || statusConfig.active
  }

  const getCategoryBadge = (category) => {
    const categoryConfig = {
      "Beach Resort": { color: "bg-blue-100 text-blue-800 hover:bg-blue-100" },
      Historical: { color: "bg-purple-100 text-purple-800 hover:bg-purple-100" },
      Cultural: { color: "bg-orange-100 text-orange-800 hover:bg-orange-100" },
      Adventure: { color: "bg-green-100 text-green-800 hover:bg-green-100" },
      Wildlife: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100" },
    }
    return categoryConfig[category] || { color: "bg-gray-100 text-gray-800 hover:bg-gray-100" }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Destination Management</h1>
          <p className="text-gray-600 mt-1">Manage tourist destinations and attractions</p>
        </div>
        <Button
          onClick={() => setShowCreateModal(true)}
          className="bg-gradient-to-r from-blue-600 to-orange-500 hover:from-blue-700 hover:to-orange-600"
        >
          <Plus className="h-4 w-4 mr-2" />
          Add Destination
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

      {/* Search */}
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
          <div className="flex items-center justify-between">
            <CardTitle>All Destinations</CardTitle>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <Input
                placeholder="Search destinations..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 w-64"
              />
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Destinations Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredDestinations.map((destination) => {
          const statusBadge = getStatusBadge(destination.status)
          const categoryBadge = getCategoryBadge(destination.category)

          return (
            <Card key={destination.id} className="border-0 shadow-lg hover:shadow-xl transition-shadow overflow-hidden">
              <div className="aspect-video relative">
                <img
                  src={destination.image || "/placeholder.svg"}
                  alt={destination.name}
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-4 right-4">
                  <Badge className={statusBadge.color}>{statusBadge.label}</Badge>
                </div>
              </div>

              <CardContent className="p-6">
                <div className="space-y-4">
                  <div>
                    <h3 className="text-xl font-bold text-gray-900">{destination.name}</h3>
                    <p className="text-gray-600 flex items-center gap-1 mt-1">
                      <MapPin className="h-4 w-4" />
                      {destination.location}
                    </p>
                  </div>

                  <p className="text-gray-600 text-sm">{destination.description}</p>

                  <div className="flex items-center gap-2">
                    <Badge className={categoryBadge.color}>{destination.category}</Badge>
                    <div className="flex items-center gap-1">
                      <Star className="h-4 w-4 text-yellow-500 fill-current" />
                      <span className="text-sm font-medium">{destination.rating}</span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4 pt-4 border-t">
                    <div>
                      <p className="text-sm text-gray-600">Bookings</p>
                      <p className="font-semibold text-gray-900">{destination.totalBookings}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600">Revenue</p>
                      <p className="font-semibold text-green-600">{destination.revenue}</p>
                    </div>
                  </div>

                  <div className="flex items-center justify-between pt-4">
                    <Button variant="outline" size="sm" className="flex-1 mr-2 bg-transparent">
                      <Eye className="h-4 w-4 mr-2" />
                      View Details
                    </Button>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="sm">
                          <MoreHorizontal className="h-4 w-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>
                          <Edit className="h-4 w-4 mr-2" />
                          Edit Destination
                        </DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">
                          <Trash2 className="h-4 w-4 mr-2" />
                          Delete Destination
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>
                </div>
              </CardContent>
            </Card>
          )
        })}
      </div>
      {showCreateModal && <CreatePlaceModal isOpen={showCreateModal} onClose={() => setShowCreateModal(false)} />}
    </div>
  )
}
