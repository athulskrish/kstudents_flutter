from django.core.cache import cache
from django.http import HttpResponseForbidden
from django.conf import settings
import time

class SecurityMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Rate limiting
        if not request.path.startswith('/static/') and not request.path.startswith('/media/'):
            ip = self.get_client_ip(request)
            if self.is_rate_limited(ip):
                return HttpResponseForbidden('Too many requests. Please try again later.')

        response = self.get_response(request)

        # Add security headers
        response['X-Content-Type-Options'] = 'nosniff'
        response['X-Frame-Options'] = 'DENY'
        response['X-XSS-Protection'] = '1; mode=block'
        response['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains'
        response['Content-Security-Policy'] = self.get_csp_policy()
        response['Referrer-Policy'] = 'strict-origin-when-cross-origin'
        response['Permissions-Policy'] = 'geolocation=(), microphone=(), camera=()'

        return response

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip

    def is_rate_limited(self, ip):
        # Rate limit settings
        RATE_LIMIT = 100  # Number of requests
        RATE_LIMIT_PERIOD = 60  # Time period in seconds

        # Get the current timestamp
        now = time.time()

        # Create a unique cache key for this IP
        cache_key = f'rate_limit_{ip}'

        # Get the request history for this IP
        requests = cache.get(cache_key, [])

        # Remove old requests outside the time window
        requests = [req_time for req_time in requests if req_time > now - RATE_LIMIT_PERIOD]

        # Add current request
        requests.append(now)

        # Update the cache
        cache.set(cache_key, requests, RATE_LIMIT_PERIOD)

        # Check if the number of requests exceeds the limit
        return len(requests) > RATE_LIMIT

    def get_csp_policy(self):
        # Define CSP policy
        csp_policies = [
            "default-src 'self'",
            "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://kit.fontawesome.com https://buttons.github.io",
            "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
            "font-src 'self' https://fonts.gstatic.com",
            "img-src 'self' data: https:",
            "connect-src 'self'",
            "frame-src 'self'",
            "object-src 'none'",
            "base-uri 'self'",
            "form-action 'self'",
        ]
        return "; ".join(csp_policies)

class AdminIPRestrictionMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Check if the request is for the admin area
        if request.path.startswith('/admin/') or request.path.startswith('/admindashboard/'):
            ALLOWED_IPS = getattr(settings, 'ADMIN_ALLOWED_IPS', [])
            ip = self.get_client_ip(request)
            
            if ALLOWED_IPS and ip not in ALLOWED_IPS:
                return HttpResponseForbidden('Access denied. Your IP is not allowed.')

        return self.get_response(request)

    def get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip 