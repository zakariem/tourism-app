"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { FileText, Download, Calendar, TrendingUp, Users, MapPin, DollarSign, BarChart3 } from "lucide-react"

const reportTypes = [
  {
    title: "Monthly Revenue Report",
    description: "Comprehensive revenue analysis and trends",
    icon: DollarSign,
    color: "text-green-600",
    bgColor: "bg-green-100",
    lastGenerated: "2024-02-01",
    size: "2.4 MB",
  },
  {
    title: "Tourist Analytics Report",
    description: "Tourist demographics and behavior analysis",
    icon: Users,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
    lastGenerated: "2024-02-01",
    size: "1.8 MB",
  },
  {
    title: "Destination Performance",
    description: "Top performing destinations and booking trends",
    icon: MapPin,
    color: "text-orange-600",
    bgColor: "bg-orange-100",
    lastGenerated: "2024-01-28",
    size: "3.1 MB",
  },
  {
    title: "Booking Trends Report",
    description: "Seasonal booking patterns and forecasting",
    icon: BarChart3,
    color: "text-purple-600",
    bgColor: "bg-purple-100",
    lastGenerated: "2024-01-25",
    size: "2.7 MB",
  },
]

const quickStats = [
  {
    title: "Reports Generated",
    value: "156",
    period: "This Month",
    icon: FileText,
    color: "text-blue-600",
    bgColor: "bg-blue-100",
  },
  {
    title: "Data Points",
    value: "45.2K",
    period: "Total Collected",
    icon: TrendingUp,
    color: "text-green-600",
    bgColor: "bg-green-100",
  },
  {
    title: "Export Downloads",
    value: "89",
    period: "This Month",
    icon: Download,
    color: "text-purple-600",
    bgColor: "bg-purple-100",
  },
]

const recentReports = [
  {
    name: "Q1 2024 Tourism Summary",
    type: "Quarterly Report",
    generatedBy: "System Auto-Generate",
    date: "2024-02-15",
    status: "completed",
    downloads: 23,
  },
  {
    name: "February Booking Analysis",
    type: "Monthly Report",
    generatedBy: "Admin User",
    date: "2024-02-10",
    status: "completed",
    downloads: 45,
  },
  {
    name: "Destination ROI Analysis",
    type: "Custom Report",
    generatedBy: "Manager",
    date: "2024-02-08",
    status: "processing",
    downloads: 0,
  },
  {
    name: "Tourist Satisfaction Survey",
    type: "Survey Report",
    generatedBy: "System Auto-Generate",
    date: "2024-02-05",
    status: "completed",
    downloads: 67,
  },
]

export function ReportsSection() {
  const getStatusBadge = (status) => {
    const statusConfig = {
      completed: { color: "bg-green-100 text-green-800 hover:bg-green-100", label: "Completed" },
      processing: { color: "bg-yellow-100 text-yellow-800 hover:bg-yellow-100", label: "Processing" },
      failed: { color: "bg-red-100 text-red-800 hover:bg-red-100", label: "Failed" },
    }
    return statusConfig[status] || statusConfig.completed
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Reports & Analytics</h1>
          <p className="text-gray-600 mt-1">Generate and download comprehensive business reports</p>
        </div>
        <Button className="bg-gradient-to-r from-blue-600 to-orange-500 hover:from-blue-700 hover:to-orange-600">
          <FileText className="h-4 w-4 mr-2" />
          Generate Custom Report
        </Button>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {quickStats.map((stat, index) => (
          <Card key={index} className="border-0 shadow-lg">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.title}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
                  <p className="text-sm text-gray-500 mt-1">{stat.period}</p>
                </div>
                <div className={`p-3 rounded-full ${stat.bgColor}`}>
                  <stat.icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Report Types */}
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-blue-50 to-orange-50 border-b">
          <CardTitle>Available Report Types</CardTitle>
        </CardHeader>
        <CardContent className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {reportTypes.map((report, index) => (
              <div key={index} className="p-6 border rounded-lg hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between mb-4">
                  <div className="flex items-center gap-3">
                    <div className={`p-2 rounded-lg ${report.bgColor}`}>
                      <report.icon className={`h-5 w-5 ${report.color}`} />
                    </div>
                    <div>
                      <h3 className="font-semibold text-gray-900">{report.title}</h3>
                      <p className="text-sm text-gray-600 mt-1">{report.description}</p>
                    </div>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="text-sm text-gray-500">
                    <p>Last generated: {report.lastGenerated}</p>
                    <p>Size: {report.size}</p>
                  </div>
                  <div className="flex gap-2">
                    <Button variant="outline" size="sm">
                      <Download className="h-4 w-4 mr-1" />
                      Download
                    </Button>
                    <Button size="sm" className="bg-gradient-to-r from-blue-600 to-orange-500">
                      Generate
                    </Button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Recent Reports */}
      <Card className="border-0 shadow-lg">
        <CardHeader className="bg-gradient-to-r from-orange-50 to-blue-50 border-b">
          <CardTitle className="flex items-center gap-2">
            <Calendar className="h-5 w-5 text-orange-600" />
            Recent Reports
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="space-y-0">
            {recentReports.map((report, index) => {
              const statusBadge = getStatusBadge(report.status)

              return (
                <div
                  key={index}
                  className="flex items-center justify-between p-6 border-b last:border-b-0 hover:bg-gray-50"
                >
                  <div className="flex-1">
                    <h4 className="font-medium text-gray-900">{report.name}</h4>
                    <div className="flex items-center gap-4 mt-1">
                      <span className="text-sm text-gray-600">{report.type}</span>
                      <span className="text-sm text-gray-600">by {report.generatedBy}</span>
                      <span className="text-sm text-gray-500">{report.date}</span>
                    </div>
                  </div>
                  <div className="flex items-center gap-4">
                    <div className="text-right">
                      <Badge className={statusBadge.color}>{statusBadge.label}</Badge>
                      {report.status === "completed" && (
                        <p className="text-sm text-gray-500 mt-1">{report.downloads} downloads</p>
                      )}
                    </div>
                    {report.status === "completed" && (
                      <Button variant="ghost" size="sm">
                        <Download className="h-4 w-4" />
                      </Button>
                    )}
                  </div>
                </div>
              )
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
