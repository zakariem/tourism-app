"use client"

import { useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Search, MoreHorizontal, Eye, Flag, Trash2, Star, MessageSquare, ThumbsUp, ThumbsDown } from "lucide-react"

const reviews = [
  {
    id: "R001",
    tourist: "Ahmed Hassan",
    destination: "Mogadishu Beach Resort",
    rating: 5,
    comment:
      "Absolutely amazing experience! The beach was pristine and the staff was incredibly welcoming. The traditional Somali cuisine was outstanding.",
    date: "2024-02-10",
    status: "approved",
    helpful: 12,
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "R002",
    tourist: "Fatima Ali",
    destination: "Berbera Historical Sites",
    rating: 4,
    comment:
      "Great historical tour with knowledgeable guides. Learned so much about Somali history and culture. Would definitely recommend!",
    date: "2024-02-08",
    status: "approved",
    helpful: 8,
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "R003",
    tourist: "Omar Mohamed",
    destination: "Hargeisa Cultural Center",
    rating: 5,
    comment:
      "Incredible cultural immersion experience. The traditional performances and local crafts were fascinating. Perfect for understanding Somali heritage.",
    date: "2024-02-05",
    status: "pending",
    helpful: 5,
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "R004",
    tourist: "Amina Abdi",
    destination: "Bosaso Coastal Tours",
    rating: 3,
    comment: "Good experience overall but the tour could be better organized. The coastal views were beautiful though.",
    date: "2024-02-03",
    status: "flagged",
    helpful: 3,
    avatar: "/placeholder.svg?height=40&width=40",
  },
  {
    id: "R005",
    tourist: "Hassan Ibrahim",
    destination: "Kismayo Wildlife Safari",
    rating: 5,
    comment:
      "Outstanding wildlife experience! Saw amazing animals and the guides were very professional. Highly recommended for nature lovers.",
    date: "2024-02-01",
    status: "approved",
    helpful: 15,
    avatar: "/placeholder.svg?height=40&width=40",
  },
]

const stats = [
  {
    title: "Total Reviews",
    value: "1,847",
    icon: MessageSquare,
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
    title: "Pending Reviews",
    value: "23",
    icon: Eye,
    color: "text-orange-600",
    bgColor: "bg-orange-100",
  },
  {
    title: "Flagged Reviews",
    value: "5",
    icon: Flag,
    color: "text-red-600",
    bgColor: "bg-red-100",
  },
]

export function ReviewsSection() {
  const [searchTerm, setSearchTerm] = useState("")

  const filteredReviews = reviews.filter(
    (review) =>
      review.tourist.toLowerCase().includes(searchTerm.toLowerCase()) ||
      review.destination.toLowerCase().includes(searchTerm.toLowerCase()) ||
      review.comment.toLowerCase().includes(searchTerm.toLowerCase()),
  )

  const getStatusBadge = (status) => {
    const statusConfig = {
      approved: { color: "bg-green-100 text-green-800 hover:bg-green-100", label: "Approved" },
      pending: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100", label: "Pending" },
      flagged: { color: "bg-red-100 text-red-800 hover:bg-red-100", label: "Flagged" },
    }
    return statusConfig[status] || statusConfig.pending
  }

  const renderStars = (rating) => {
    return Array.from({ length: 5 }, (_, index) => (
      <Star key={index} className={`h-4 w-4 ${index < rating ? "text-yellow-500 fill-current" : "text-gray-300"}`} />
    ))
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Reviews & Feedback</h1>
          <p className="text-gray-600 mt-1">Monitor and manage tourist reviews and ratings</p>
        </div>
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
            <CardTitle>All Reviews</CardTitle>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
              <Input
                placeholder="Search reviews..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10 w-64"
              />
            </div>
          </div>
        </CardHeader>
      </Card>

      {/* Reviews List */}
      <div className="space-y-4">
        {filteredReviews.map((review) => {
          const statusBadge = getStatusBadge(review.status)

          return (
            <Card key={review.id} className="border-0 shadow-lg hover:shadow-xl transition-shadow">
              <CardContent className="p-6">
                <div className="space-y-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <Avatar className="h-12 w-12">
                        <AvatarImage src={review.avatar || "/placeholder.svg"} />
                        <AvatarFallback className="bg-gradient-to-r from-blue-500 to-orange-500 text-white">
                          {review.tourist
                            .split(" ")
                            .map((n) => n[0])
                            .join("")}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <h3 className="font-semibold text-gray-900">{review.tourist}</h3>
                        <p className="text-sm text-gray-600">{review.destination}</p>
                        <p className="text-xs text-gray-500">{review.date}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-3">
                      <Badge className={statusBadge.color}>{statusBadge.label}</Badge>
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
                            <Flag className="h-4 w-4 mr-2" />
                            Flag Review
                          </DropdownMenuItem>
                          <DropdownMenuItem className="text-red-600">
                            <Trash2 className="h-4 w-4 mr-2" />
                            Delete Review
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </div>
                  </div>

                  <div className="flex items-center gap-2">
                    <div className="flex items-center">{renderStars(review.rating)}</div>
                    <span className="text-sm font-medium text-gray-700">{review.rating}.0</span>
                  </div>

                  <p className="text-gray-700 leading-relaxed">{review.comment}</p>

                  <div className="flex items-center justify-between pt-4 border-t">
                    <div className="flex items-center gap-4">
                      <Button variant="ghost" size="sm" className="text-green-600 hover:text-green-700">
                        <ThumbsUp className="h-4 w-4 mr-1" />
                        Helpful ({review.helpful})
                      </Button>
                      <Button variant="ghost" size="sm" className="text-gray-600 hover:text-gray-700">
                        <ThumbsDown className="h-4 w-4 mr-1" />
                        Not Helpful
                      </Button>
                    </div>
                    <div className="flex gap-2">
                      {review.status === "pending" && (
                        <>
                          <Button
                            size="sm"
                            variant="outline"
                            className="text-green-600 border-green-200 hover:bg-green-50 bg-transparent"
                          >
                            Approve
                          </Button>
                          <Button
                            size="sm"
                            variant="outline"
                            className="text-red-600 border-red-200 hover:bg-red-50 bg-transparent"
                          >
                            Reject
                          </Button>
                        </>
                      )}
                    </div>
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
