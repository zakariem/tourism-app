"use client"

import { OverviewSection } from "./sections/overview-section"
import { TouristsSection } from "./sections/tourists-section"
import { BookingsSection } from "./sections/bookings-section"
import { DestinationsSection } from "./sections/destinations-section"
import { AnalyticsSection } from "./sections/analytics-section"
import { AccommodationsSection } from "./sections/accommodations-section"
import { ReviewsSection } from "./sections/reviews-section"
import { ReportsSection } from "./sections/reports-section"

export function DashboardContent({ activeSection }) {
  const renderSection = () => {
    switch (activeSection) {
      case "overview":
        return <OverviewSection />
      case "analytics":
        return <AnalyticsSection />
      case "tourists":
        return <TouristsSection />
      case "bookings":
        return <BookingsSection />
      case "destinations":
        return <DestinationsSection />
      case "accommodations":
        return <AccommodationsSection />
      case "reviews":
        return <ReviewsSection />
      case "reports":
        return <ReportsSection />
      default:
        return <OverviewSection />
    }
  }

  return <div className="flex-1 p-6">{renderSection()}</div>
}
