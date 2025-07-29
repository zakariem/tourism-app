"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Search, Plus, MoreHorizontal, Eye, Edit, Trash2, Building2, Star, Users, DollarSign } from "lucide-react"

const accommodations = [
  {
    id: "H001",
    name: "Mogadishu Grand Hotel",
    type: "Hotel",
    location: "Mogadishu, Banaadir",
    rating: 4.8,
    rooms: 120,
    occupancy: 85,
    priceRange: "$80-150",
    status: "active",
    amenities: ["WiFi", "Pool", "Restaurant", "Spa"],
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "H002",
    name: "Berbera Beach Lodge",
    type: "Lodge",
    location: "Berbera, Sahil",
    rating: 4.6,
    rooms: 45,
    occupancy: 92,
    priceRange: "$60-120",
    status: "active",
    amenities: ["WiFi", "Beach Access", "Restaurant"],
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "H003",
    name: "Hargeisa Cultural Inn",
    type: "Inn",
    location: "Hargeisa, Maroodi Jeex",
    rating: 4.5,
    rooms: 30,
    occupancy: 78,
    priceRange: "$40-80",
    status: "active",
    amenities: ["WiFi", "Cultural Tours", "Restaurant"],
    image: "/placeholder.svg?height=200&width=300",
  },
  {
    id: "H004",
    name: "Bosaso Coastal Resort",
    type: "Resort",
    location: "Bosaso, Bari",
    rating: 4.7,
    rooms: 80,
    occupancy: 88,
    priceRange: "$90-180",
    status: "maintenance",
    amenities: ["WiFi", "Pool", "Beach Access", "Water Sports"],
    image: "/placeholder.svg?height=200&width=300",
  },
]

const stats = [
  {
    title: "Total Properties",
    value: "28",
    icon: Building2,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Average Rating",
    value: "4.6",
    icon: Star,
    color: "text-yellow-600",
    bgColor: "bg-yellow-100",
  },
  {
    title: "Total Rooms",
    value: "1,245",
    icon: Users,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Avg. Occupancy",
    value: "86%",
    icon: DollarSign,
    color: "text-purple-600",
    bgColor: "bg-purple-100",
  },
]

export function AccommodationsSection() {
  const [searchTerm, setSearchTerm] = useState("")

  const filteredAccommodations = accommodations.filter(
    (accommodation) =>
      accommodation.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      accommodation.location.toLowerCase().includes(searchTerm.toLowerCase()) ||
      accommodation.type.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const getStatusBadge = (status) => {
    const statusConfig = {
      active: { color: "bg-green-100 text-green-800 hover:bg-green-100", label: "Active" },
      maintenance: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100", label: "Maintenance" },
      inactive: { color: "bg-red-100 text-red-800 hover:bg-red-100", label: "Inactive" },
    }
    return statusConfig[status] || statusConfig.active
  }

  const getTypeBadge = (type) => {
    const typeConfig = {
      Hotel: { color: "bg-blue-100 text-blue-800 hover:bg-blue-100" },
      Resort: { color: "bg-purple-100 text-purple-800 hover:bg-purple-100" },
      Lodge: { color: "bg-green-100 text-green-800 hover:bg-green-100" },
      Inn: { color: "bg-orange-100 text-orange-800 hover:bg-orange-100" },
    }
    return typeConfig[type] || { color: "bg-gray-100 text-gray-800 hover:bg-gray-100" }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Hotels & Accommodations</h1>
          <p className="text-gray-600 mt-1">Manage lodging facilities and accommodations</p>
        </div>
        <Button className="bg-gradient-to-r from-blue-600 to-orange-500 hover:from-blue-700 hover:to-orange-600">
          <Plus className="h-4 w-4 mr-2" />
          Add Property
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
            <CardTitle>All Properties</CardTitle>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <Input
                placeholder="Search properties..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 w-64"
              />
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Properties Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredAccommodations.map((accommodation) => {
          const statusBadge = getStatusBadge(accommodation.status)
          const typeBadge = getTypeBadge(accommodation.type)

          return (
            <Card
              key={accommodation.id}
              className="border-0 shadow-lg hover:shadow-xl transition-shadow overflow-hidden"
            >
              <div className="aspect-video relative">
                <img
                  src={accommodation.image || "/placeholder.svg"}
                  alt={accommodation.name}
                  className="w-full h-full object-cover"
                />
                <div className="absolute top-4 right-4 flex gap-2">
                  <Badge className={statusBadge.color}>{statusBadge.label}</Badge>
                </div>
              </div>

              <CardContent className="p-6">
                <div className="space-y-4">
                  <div>
                    <h3 className="text-xl font-bold text-gray-900">{accommodation.name}</h3>
                    <p className="text-gray-600 text-sm mt-1">{accommodation.location}</p>
                  </div>

                  <div className="flex items-center gap-2">
                    <Badge className={typeBadge.color}>{accommodation.type}</Badge>
                    <div className="flex items-center gap-1">
                      <Star className="h-4 w-4 text-yellow-500 fill-current" />
                      <span className="text-sm font-medium">{accommodation.rating}</span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <p className="text-sm text-gray-600">Rooms</p>
                      <p className="font-semibold text-gray-900">{accommodation.rooms}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-600">Occupancy</p>
                      <p className="font-semibold text-green-600">{accommodation.occupancy}%</p>
                    </div>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600">Price Range</p>
                    <p className="font-semibold text-gray-900">{accommodation.priceRange}</p>
                  </div>

                  <div>
                    <p className="text-sm text-gray-600 mb-2">Amenities</p>
                    <div className="flex flex-wrap gap-1">
                      {accommodation.amenities.map((amenity, index) => (
                        <Badge key={index} variant="outline" className="text-xs">
                          {amenity}
                        </Badge>
                      ))}
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
                          Edit Property
                        </DropdownMenuItem>
                        <DropdownMenuItem className="text-red-600">
                          <Trash2 className="h-4 w-4 mr-2" />
                          Delete Property
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
    </div>
  )
}
