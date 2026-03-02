## 📂 Serbisyo Database Schema (Plain Text)

### **Users**
- `_id`  
- `is_customer` (Boolean, default = true)  
- `is_provider` (Boolean, default = false; can be activated later)  
- `is_admin` (Boolean, default = false)  
- `admin_role` (optional: superadmin, moderator, finance, etc.)  
- `name`  
- `email`  
- `password_hash`  
- `phone`  
- `address` (street, city, province, coordinates for geolocation)  
- `profile_picture`  
- `ratings` (average rating if provider role is active)  
- `created_at`  
- `updated_at`  

👉 **Note**: A single account can hold multiple roles (e.g., customer + provider + admin). Signup defaults to `is_customer = true`.

---

### **Services**
- `_id`  
- `name` (e.g., Plumbing, Gardening)  
- `description`  
- `category`  
- `base_price`  
- `created_at`  
- `updated_at`  

---

### **Bookings**
- `_id`  
- `customer_id` (reference Users)  
- `provider_id` (reference Users)  
- `service_id` (reference Services)  
- `status` (pending, accepted, rejected, completed, cancelled)  
- `scheduled_date`  
- `location` (lat, lng)  
- `payment_id` (reference Payments)  
- `payment_method` (stripe, paypal, gcash, etc.)  
- `created_at`  
- `updated_at`  

---

### **Payments**
- `_id`  
- `booking_id` (reference Bookings)  
- `amount`  
- `currency` (PHP)  
- `method` (stripe, paypal, gcash)  
- `status` (pending, paid, refunded)  
- `transaction_reference`  
- `created_at`  

---

### **Messages**
- `_id`  
- `booking_id` (reference Bookings)  
- `sender_id` (reference Users)  
- `receiver_id` (reference Users)  
- `content`  
- `flagged` (true if prohibited topic detected)  
- `created_at`  

---

### **Reviews**
- `_id`  
- `booking_id` (reference Bookings)  
- `customer_id`  
- `provider_id`  
- `rating` (1–5 stars)  
- `comment`  
- `created_at`  

---

### **Admin Logs**
- `_id`  
- `action` (e.g., user banned, payment refunded)  
- `performed_by` (reference Users with `is_admin = true`)  
- `details` (object with extra info)  
- `created_at`  

