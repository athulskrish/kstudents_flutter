# Kerala Tech Reach - Django Project Documentation

## Project Overview

This is a Django-based web application for Kerala Tech Reach, a platform that provides educational resources, news, events, and other services for students. The application consists of multiple modules including an admin dashboard, API endpoints, and public-facing pages.

## Tech Stack

- **Backend Framework**: Django 
- **API Framework**: Django REST Framework
- **Authentication**: JWT (JSON Web Tokens)
- **Database**: SQLite (development)
- **Frontend Integration**: CORS enabled for cross-origin requests
- **Security**: Multiple security middlewares implemented

## Project Structure

### Core Applications

1. **keralatechreach_django**: Main project configuration
2. **admindashboard**: Admin interface for content management
3. **api**: REST API endpoints for mobile/web clients
4. **publicpage**: Public-facing website pages

### Key Features

- User authentication and authorization
- Content management system
- REST API for mobile applications
- Educational resources (question papers, notes)
- Events and news publication
- Affiliate marketing integration
- File uploads and management
- Newsletter subscription

## Database Models

### Educational Resources

- **University**: Educational institutions
- **Degree**: Academic programs offered by universities
- **QuestionPaper**: Past examination papers
- **Note**: Study materials
- **Exam**: Upcoming examinations
- **EntranceNotification**: Notifications about entrance exams

### Content Management

- **News**: Articles and updates
- **Event**: Upcoming events with details
- **EventCategory**: Categories for events
- **Initiative**: Organization initiatives
- **Gallery**: Image gallery
- **Testimonial**: User testimonials
- **FAQ**: Frequently asked questions

### User Management

- **UserProfile**: Extended user information
- **District**: Geographic districts for user categorization
- **ActivityLog**: User activity tracking

### Marketing & Communication

- **AffiliateCategory**: Categories for affiliate products
- **AffiliateProduct**: Products for affiliate marketing
- **AffiliateSliderItem**: Slider items for affiliate section
- **AffiliateBudgetSelection**: Budget-based product recommendations
- **ContactMessage**: Messages from contact forms
- **NewsletterSubscriber**: Newsletter subscription management
- **AdSettings**: Advertisement placement and management

## API Endpoints

The API provides RESTful endpoints for:

- User authentication (login, registration)
- Educational resources (universities, degrees, question papers, notes)
- Content (news, events, exams, notifications)
- Affiliate marketing products
- Contact form submissions

All API endpoints follow REST conventions and most are read-only for public consumption, with protected endpoints for data modification.

## Security Features

- JWT-based authentication
- CSRF protection
- XSS prevention
- Content-Type sniffing protection
- HSTS implementation
- Secure cookies
- Session security (timeouts, HTTP-only cookies)
- Strong password validation

## Development Setup

### Requirements

Required packages are listed in requirements.txt and include:
- Django
- Django REST Framework
- Django REST Framework SimpleJWT
- Django CORS Headers
- Django Filter
- Pillow (for image processing)
- Channels (for WebSocket support)
- Django Jazzmin (for admin UI enhancements)

### Configuration

The project uses environment variables for sensitive configuration settings.

### Static Files

Static files are managed using WhiteNoise middleware, with static and media directories configured for file serving.

## Public Pages

The website offers several public-facing pages:
- Home page with featured content
- News listings and detail pages
- Events calendar and details
- Search functionality
- Contact form
- About and services pages

## Admin Dashboard

The admin dashboard provides an interface for content management with:
- User management
- Content creation and publication
- File uploads
- Analytics tracking
- Settings management

## Security Considerations

- Environment-specific security settings (development vs production)
- Rate limiting implementation
- User activity logging
- Secure file upload handling
- Authorization checks throughout the application

## Deployment Notes

For production deployment:
- Enable production security settings
- Configure a production-grade database
- Set up proper static file serving
- Implement HTTPS
- Configure proper hosting environment

## Future Development

Potential areas for enhancement:
- Advanced analytics integration
- Enhanced mobile API features
- More educational resource types
- Improved search functionality
- Social media integration 