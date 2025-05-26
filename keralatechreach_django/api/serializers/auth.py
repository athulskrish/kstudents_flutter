from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def validate_password(self, value):
        validate_password(value)
        # Custom strong password policy
        if len(value) < 10:
            raise serializers.ValidationError('Password must be at least 10 characters long.')
        if not any(c.isupper() for c in value):
            raise serializers.ValidationError('Password must contain an uppercase letter.')
        if not any(c.islower() for c in value):
            raise serializers.ValidationError('Password must contain a lowercase letter.')
        if not any(c.isdigit() for c in value):
            raise serializers.ValidationError('Password must contain a digit.')
        if not any(c in '!@#$%^&*()_+-=[]{}|;:,.<>?/~' for c in value):
            raise serializers.ValidationError('Password must contain a special character.')
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password']
        )
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['username'] = user.username
        token['email'] = user.email
        return token 