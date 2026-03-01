# Use Node.js 18 Alpine for smaller image size
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files first for better caching
COPY package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Copy the rest of the application
COPY . .

# Create uploads directory if it doesn't exist
RUN mkdir -p public/uploads

# Expose the port (Railway sets PORT environment variable)
EXPOSE $PORT

# Start the application
CMD ["node", "src/app.js"]
