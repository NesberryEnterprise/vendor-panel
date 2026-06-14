# BUILD STAGE
FROM node:24-alpine AS build
WORKDIR /build

# Build arguments. Railway injects service variables as --build-arg, so declare
# each as ARG, then export to ENV so vite's loadEnv() (which merges process.env
# VITE_* entries) picks them up during `vite build`. Without the ENV export the
# args are invisible to the build and the panel bakes in localhost defaults.
ARG VITE_MEDUSA_BASE
ARG VITE_MEDUSA_BACKEND_URL
ARG VITE_MEDUSA_STOREFRONT_URL
ARG VITE_PUBLISHABLE_API_KEY
ARG VITE_TALK_JS_APP_ID
ARG VITE_DISABLE_SELLERS_REGISTRATION
ARG VITE_MEDUSA_PROJECT
ENV VITE_MEDUSA_BASE=$VITE_MEDUSA_BASE \
    VITE_MEDUSA_BACKEND_URL=$VITE_MEDUSA_BACKEND_URL \
    VITE_MEDUSA_STOREFRONT_URL=$VITE_MEDUSA_STOREFRONT_URL \
    VITE_PUBLISHABLE_API_KEY=$VITE_PUBLISHABLE_API_KEY \
    VITE_TALK_JS_APP_ID=$VITE_TALK_JS_APP_ID \
    VITE_DISABLE_SELLERS_REGISTRATION=$VITE_DISABLE_SELLERS_REGISTRATION \
    VITE_MEDUSA_PROJECT=$VITE_MEDUSA_PROJECT

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build the application
RUN yarn build:preview

# RUNTIME STAGE
FROM node:24-alpine AS runtime

# Install serve globally
RUN npm install -g serve

# Copy built files
COPY --from=build /build/dist /app

WORKDIR /app

EXPOSE 7000

# Serve static files on Railway's $PORT (fallback 7000 for local/docker-compose)
CMD ["sh", "-c", "serve -s . -l ${PORT:-7000}"]
