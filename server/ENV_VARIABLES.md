# Environment Variables

This application uses environment variables for configuration. Follow these steps to set them up:

## Setup

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Update the values in `.env` file according to your environment.

## Available Variables

### CLIENT_URL
- **Description**: URL of the frontend client application
- **Required**: Yes (in production)
- **Default**: `http://localhost:5173` (in development)
- **Example**: `https://hacker-news-app-nu.vercel.app`

This variable is used for:
- CORS configuration
- ActionCable allowed origins
- Any frontend URL references

## Production Deployment

For production deployment, make sure to set the `CLIENT_URL` environment variable in your hosting platform (Heroku, Railway, etc.).

Example for Heroku:
```bash
heroku config:set CLIENT_URL=https://your-frontend-domain.com
```

## Development

For local development, the `.env` file will be automatically loaded. You can override any variable by setting it in your shell:

```bash
CLIENT_URL=http://localhost:3000 rails server
```
