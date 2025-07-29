"use client"

import { BarChart3, Calendar, Home, MapPin, Settings, Users, Plane, Building2, Star, TrendingUp } from "lucide-react"
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

const menuItems = [
  {
    title: "Overview",
    icon: Home,
    id: "overview",
  },
  {
    title: "Analytics",
    icon: BarChart3,
    id: "analytics",
  },
  {
    title: "Tourists",
    icon: Users,
    id: "tourists",
  },
  {
    title: "Bookings",
    icon: Calendar,
    id: "bookings",
  },
  {
    title: "Destinations",
    icon: MapPin,
    id: "destinations",
  },
  {
    title: "Hotels & Lodges",
    icon: Building2,
    id: "accommodations",
  },
  {
    title: "Reviews",
    icon: Star,
    id: "reviews",
  },
  {
    title: "Reports",
    icon: TrendingUp,
    id: "reports",
  },
]

export function AdminSidebar({ activeSection, setActiveSection }) {
  return (
    <Sidebar className="border-r border-orange-200">
      <SidebarHeader className="border-b border-orange-200 bg-gradient-to-r from-blue-600 to-orange-500 text-white">
        <div className="flex items-center gap-3 px-3 py-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/20">
            <Plane className="h-6 w-6" />
          </div>
          <div>
            <h2 className="text-lg font-bold">Somalia Tourism</h2>
            <p className="text-sm text-white/80">Admin Dashboard</p>
          </div>
        </div>
      </SidebarHeader>

      <SidebarContent className="bg-white">
        <SidebarGroup>
          <SidebarGroupLabel className="text-gray-600 font-semibold">Management</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {menuItems.map((item) => (
                <SidebarMenuItem key={item.id}>
                  <SidebarMenuButton
                    onClick={() => setActiveSection(item.id)}
                    isActive={activeSection === item.id}
                    className={`w-full justify-start gap-3 ${
                      activeSection === item.id
                        ? "bg-gradient-to-r from-blue-500 to-orange-500 text-white"
                        : "hover:bg-orange-50 text-gray-700"
                    }`}
                  >
                    <item.icon className="h-5 w-5" />
                    <span>{item.title}</span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="border-t border-orange-200 bg-white">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton className="w-full justify-start gap-3 hover:bg-orange-50">
              <Settings className="h-5 w-5" />
              <span>Settings</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
        <div className="flex items-center gap-3 px-3 py-3">
          <Avatar className="h-8 w-8">
            <AvatarImage src="/placeholder.svg?height=32&width=32" />
            <AvatarFallback className="bg-gradient-to-r from-blue-500 to-orange-500 text-white">AD</AvatarFallback>
          </Avatar>
          <div className="flex-1 text-sm">
            <p className="font-medium text-gray-900">Admin User</p>
            <p className="text-gray-500">admin@somalia-tourism.so</p>
          </div>
        </div>
      </SidebarFooter>
    </Sidebar>
  )
}
