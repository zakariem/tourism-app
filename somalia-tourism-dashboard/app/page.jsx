"use client"

import { useState } from "react"
import { SidebarProvider } from "@/components/ui/sidebar"
import { AdminSidebar } from "@/components/admin-sidebar"
import { DashboardContent } from "@/components/dashboard-content"

export default function AdminDashboard() {
  const [activeSection, setActiveSection] = useState("overview")

  return (
    <SidebarProvider defaultOpen={true}>
      <div className="flex min-h-screen w-full bg-gradient-to-br from-blue-50 to-orange-50">
        <AdminSidebar activeSection={activeSection} setActiveSection={setActiveSection} />
        <main className="flex-1">
          <DashboardContent activeSection={activeSection} />
        </main>
      </div>
    </SidebarProvider>
  )
}
