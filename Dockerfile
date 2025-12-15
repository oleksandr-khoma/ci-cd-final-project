# Use Node.js LTS version
FROM node:20-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy application source
COPY src ./src

# Expose port
EXPOSE 3000

# Set environment to production
ENV NODE_ENV=production

# Run the application
CMD ["node", "src/app.js"]

