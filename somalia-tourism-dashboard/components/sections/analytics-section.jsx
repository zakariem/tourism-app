"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { BarChart3, TrendingUp, Users, MapPin, Calendar, DollarSign, Star, Globe } from "lucide-react"

const monthlyStats = [
  { month: "Jan", bookings: 145, revenue: 32400, tourists: 89 },
  { month: "Feb", bookings: 189, revenue: 41200, tourists: 112 },
  { month: "Mar", bookings: 234, revenue: 52800, tourists: 156 },
  { month: "Apr", bookings: 198, revenue: 45600, tourists: 134 },
  { month: "May", bookings: 267, revenue: 58900, tourists: 178 },
  { month: "Jun", bookings: 312, revenue: 67200, tourists: 203 },
]

const topDestinations = [
  { name: "Mogadishu Beach Resort", bookings: 156, revenue: "$45,200", growth: "+12%" },
  { name: "Berbera Historical Sites", bookings: 134, revenue: "$38,900", growth: "+8%" },
  { name: "Hargeisa Cultural Center", bookings: 98, revenue: "$28,400", growth: "+15%" },
  { name: "Bosaso Coastal Tours", bookings: 87, revenue: "$24,100", growth: "+5%" },
  { name: "Kismayo Wildlife Safari", bookings: 65, revenue: "$19,800", growth: "+18%" },
]

const touristOrigins = [
  { country: "Somalia", percentage: 35, tourists: 996 },
  { country: "Ethiopia", percentage: 22, tourists: 626 },
  { country: "Kenya", percentage: 18, tourists: 512 },
  { country: "Djibouti", percentage: 12, tourists: 341 },
  { country: "Other", percentage: 13, tourists: 370 },
]

const stats = [
  {
    title: "Total Revenue",
    value: "$298,100",
    change: "+15.3%",
    icon: DollarSign,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Monthly Bookings",
    value: "312",
    change: "+23.1%",
    icon: Calendar,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Active Tourists",
    value: "2,845",
    change: "+8.7%",
    icon: Users,
    color: "text-purple-600",
    bgColor: "bg-purple-100",
  },
  {
    title: "Avg. Rating",
    value: "4.6",
    change: "+0.2",
    icon: Star,
    color: "text-yellow-600",
    bgColor: "bg-yellow-100",
  },
]

export function AnalyticsSection() {
  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Analytics Dashboard</h1>
        <p className="text-gray-600 mt-1">Comprehensive insights into tourism performance</p>
      </div>

      {/* Key Metrics */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <Card key={index} className="border-0 shadow-lg">
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
        {/* Monthly Performance */}
        <Card className="border-0 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
            <CardTitle className="flex items-center gap-2">
              <BarChart3 className="h-5 w-5 text-blue-600" />
              Monthly Performance
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {monthlyStats.map((month, index) => (
                <div key={month.month} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{month.month} 2024</p>
                    <div className="flex items-center gap-4 mt-1">
                      <span className="text-sm text-gray-600">{month.bookings} bookings</span>
                      <span className="text-sm text-gray-600">{month.tourists} tourists</span>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-green-600">${month.revenue.toLocaleString()}</p>
                    <div className="w-24 bg-gray-200 rounded-full h-2 mt-2">
                      <div
                        className="bg-gradient-to-r from-blue-500 to-orange-500 h-2 rounded-full"
                        style={{ width: `${(month.bookings / 350) * 100}%` }}
                      ></div>
                    </div>
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
              Top Performing Destinations
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {topDestinations.map((destination, index) => (
                <div key={index} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{destination.name}</p>
                    <p className="text-sm text-gray-600">{destination.bookings} bookings</p>
                  </div>
                  <div className="text-right">
                    <p className="font-semibold text-gray-900">{destination.revenue}</p>
                    <Badge variant="outline" className="bg-green-100 text-green-800 border-green-200 mt-1">
                      {destination.growth}
                    </Badge>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Tourist Origins */}
        <Card className="border-0 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-purple-50 to-blue-50 border-b">
            <CardTitle className="flex items-center gap-2">
              <Globe className="h-5 w-5 text-purple-600" />
              Tourist Origins
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {touristOrigins.map((origin, index) => (
                <div key={origin.country} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-gray-900">{origin.country}</span>
                    <div className="text-right">
                      <span className="font-semibold text-gray-900">{origin.percentage}%</span>
                      <p className="text-sm text-gray-600">{origin.tourists} tourists</p>
                    </div>
                  </div>
                  <div className="w-full bg-gray-200 rounded-full h-2">
                    <div
                      className="bg-gradient-to-r from-purple-500 to-blue-500 h-2 rounded-full"
                      style={{ width: `${origin.percentage}%` }}
                    ></div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Performance Insights */}
        <Card className="border-0 shadow-lg">
          <CardHeader className="bg-gradient-to-r from-green-50 to-orange-50 border-b">
            <CardTitle className="flex items-center gap-2">
              <TrendingUp className="h-5 w-5 text-green-600" />
              Key Insights
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-6">
              <div className="p-4 bg-green-50 rounded-lg border-l-4 border-green-500">
                <h4 className="font-semibold text-green-800">Revenue Growth</h4>
                <p className="text-sm text-green-700 mt-1">
                  Monthly revenue increased by 15.3% compared to last month, driven by higher booking rates.
                </p>
              </div>

              <div className="p-4 bg-blue-50 rounded-lg border-l-4 border-blue-500">
                <h4 className="font-semibold text-blue-800">Peak Season</h4>
                <p className="text-sm text-blue-700 mt-1">
                  June shows the highest booking activity with 312 bookings, indicating peak tourism season.
                </p>
              </div>

              <div className="p-4 bg-orange-50 rounded-lg border-l-4 border-orange-500">
                <h4 className="font-semibold text-orange-800">Top Destination</h4>
                <p className="text-sm text-orange-700 mt-1">
                  Mogadishu Beach Resort leads with 156 bookings and $45,200 revenue this month.
                </p>
              </div>

              <div className="p-4 bg-purple-50 rounded-lg border-l-4 border-purple-500">
                <h4 className="font-semibold text-purple-800">Customer Satisfaction</h4>
                <p className="text-sm text-purple-700 mt-1">
                  Average rating improved to 4.6 stars, showing enhanced tourist experience quality.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}
