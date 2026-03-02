# 📑 Product Requirements Document (PRD)  
**Project Name:** Serbisyo  
**Type:** Home Services Booking Platform (Airbnb‑Inspired)  
**Version:** MVP (8‑week development cycle)  

---

## 1. Purpose
Serbisyo aims to digitize and streamline the home services industry by providing a trusted platform where customers can book service providers (plumbing, gardening, housekeeping, etc.) securely. Inspired by Airbnb, Serbisyo will offer dashboards for customers, providers, and superadmins, ensuring all transactions remain in‑app with no cash handling.

---

## 2. Goals
- Deliver a functional MVP within 8 weeks for **presentation/pitch purposes**.  
- Provide a **demo environment using free hosting tiers** (Vercel, Render, MongoDB Atlas).  
- Validate core workflows: booking, payments, messaging, dashboards.  
- Demonstrate scalability and monetization potential to investors.  

---

## 3. Target Users
- **Customers**: Individuals booking home services.  
- **Service Providers**: Professionals offering services.  
- **Superadmin/Stakeholders**: Platform owners monitoring transactions, enforcing rules, and viewing analytics.  

---

## 4. Core Features
### Customer App
- User registration & authentication (JWT + OAuth).  
- Browse services and providers.  
- Booking options:  
  - Book a **specific provider**.  
  - Book the **nearest available provider** (geolocation matching).  
- Secure in‑app payments (Stripe/PayPal/local gateways).  
- Messaging system with prohibited topic detection (e.g., “cash,” “outside app”).  
- Ratings and reviews for providers.  

### Provider Dashboard
- Manage availability, bookings, and schedules.  
- Track earnings and ratings.  
- Messaging with customers (subject to filters).  
- Airbnb‑style dashboard UI.  

### Superadmin Dashboard
- Manage users, providers, and services.  
- Monitor transactions and revenue.  
- Analytics and reporting for stakeholders.  
- Control prohibited message detection and enforcement.  

---

## 5. Non‑Functional Requirements
- **Hosting (Demo)**: Free tiers (Vercel, Render, MongoDB Atlas, Firebase).  
- **Performance**: Handle up to 500 concurrent demo users.  
- **Security**: All transactions in‑app, PCI‑compliant payment integration.  
- **Scalability**: Modular monolith for MVP; migration path to serverful hosting for production.  
- **Reliability**: Demo hosting may have cold starts; acceptable for pitch purposes.  

---

## 6. Development Timeline (8 Weeks)
- **Phase 1 (Weeks 1–5)**:  
  - Build core MVP features (customer app, provider dashboard, superadmin dashboard).  
  - Implement booking logic (specific provider vs. nearest provider).  
  - Add messaging system with prohibited topic detection.  
  - Internal testing and client review.  

- **Phase 2 (Weeks 6–8)**:  
  - Apply revisions based on client feedback.  
  - Polish UI/UX (Airbnb‑style dashboards).  
  - Deploy to free hosting platforms for demo/pitch.  
  - Prepare presentation materials (screenshots, live demo link).  

---

## 7. Proposed Cost
- **MVP Development Cost (excluding hosting): ₱25,000**  
- **Hosting for Demo**: ₱0 (excluding optional domain).  
- **Scaling Hosting (Production)**: ₱3,000–₱6,000/month.  

---

## 8. Risks & Challenges
- **Cold Starts**: Free backend hosting may cause delays.  
- **Message Filtering**: Must balance strictness with usability (avoid false positives).  
- **Payment Compliance**: Requires secure backend integration.  
- **Scalability**: Migration to serverful hosting needed for full deployment.  

---

## 9. Success Metrics
- Functional MVP delivered in 8 weeks.  
- Live demo hosted on free tiers for investor pitch.  
- Smooth booking flow (browse → book → pay → notify).  
- Positive client feedback during Phase 1 revisions.  
- Investor interest based on demo presentation.  

