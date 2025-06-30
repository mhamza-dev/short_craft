# ShortCraft

A modern Phoenix application for creating and managing short-form video content with advanced video processing capabilities, OAuth2 authentication, and real-time features.

## Features

- **Video Processing**: Advanced video processing using Membrane framework
- **OAuth2 Authentication**: Social login with Google, GitHub, and Facebook
- **Real-time Features**: Live updates and interactions
- **Background Jobs**: Asynchronous processing with Oban
- **Modern UI**: Beautiful interface with Tailwind CSS and Heroicons
- **Activity Tracking**: User activity monitoring and analytics

## Tech Stack

### Backend

- **Phoenix Framework** - Web framework for Elixir
- **Ecto** - Database wrapper and query builder
- **PostgreSQL** - Primary database
- **Membrane** - Multimedia processing framework
- **Oban** - Background job processing
- **Ueberauth** - OAuth2 authentication

### Frontend

- **Tailwind CSS** - Utility-first CSS framework
- **Heroicons** - Beautiful SVG icons
- **esbuild** - JavaScript bundler
- **Phoenix LiveView** - Real-time user interface

### Authentication

- **Argon2** - Password hashing
- **OAuth2** - Social authentication
- **Ueberauth** - Authentication framework

### Video Processing

- **Membrane Core** - Multimedia processing
- **FFmpeg Integration** - Video encoding/decoding
- **MP4 Support** - Video container format
- **H.264 Codec** - Video compression

## Prerequisites

- Elixir 1.14+
- Erlang 25+
- PostgreSQL
- FFmpeg (for video processing)

## Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd short_craft
```

2. Install dependencies:

```bash
mix deps.get
```

3. Setup the database:

```bash
mix ecto.setup
```

4. Install and build assets:

```bash
mix assets.setup
mix assets.build
```

5. Start the Phoenix server:

```bash
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Development

### Available Mix Tasks

- `mix setup` - Install dependencies and setup database
- `mix ecto.setup` - Create database, run migrations, and seed data
- `mix ecto.reset` - Drop database and recreate
- `mix assets.build` - Build frontend assets
- `mix assets.deploy` - Build and minify assets for production

### Environment Variables

Create a `.env` file with the following variables:

```env
# Database
DATABASE_URL=postgresql://username:password@localhost/short_craft_dev

# OAuth2 Providers
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
FACEBOOK_CLIENT_ID=your_facebook_client_id
FACEBOOK_CLIENT_SECRET=your_facebook_client_secret

# Application
SECRET_KEY_BASE=your_secret_key_base
```

## Project Structure

```
lib/
├── short_craft/
│   ├── accounts/          # User authentication and management
│   ├── shorts/            # Video content and activities
│   └── application.ex     # Application supervision tree
└── short_craft_web/
    ├── controllers/       # HTTP controllers
    ├── live/             # LiveView modules
    ├── components/       # Reusable UI components
    └── router.ex         # URL routing
```

## Video Processing

The application uses the Membrane framework for video processing:

- **File Input/Output**: Handle video file uploads and downloads
- **FFmpeg Integration**: Video encoding, decoding, and format conversion
- **MP4 Support**: Process MP4 video containers
- **H.264 Codec**: Advanced video compression

## Authentication

Multiple authentication methods are supported:

- **Email/Password**: Traditional authentication with Argon2 hashing
- **Google OAuth2**: Sign in with Google account
- **GitHub OAuth2**: Sign in with GitHub account
- **Facebook OAuth2**: Sign in with Facebook account

## Background Jobs

Oban is used for background job processing:

- Video processing tasks
- Email notifications
- Data analytics
- File cleanup

## Testing

Run the test suite:

```bash
mix test
```

## Deployment

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Production Build

```bash
mix assets.deploy
MIX_ENV=prod mix release
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Learn more

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Elixir Language](https://elixir-lang.org/)
- [Membrane Framework](https://membrane.stream/)
- [Ueberauth](https://github.com/ueberauth/ueberauth)
- [Oban](https://github.com/sorentwo/oban)
