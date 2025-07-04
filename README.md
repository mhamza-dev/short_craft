# ShortCraft

Transform YouTube videos into engaging shorts with ease.

## Features

- **Smart Download:** Download YouTube videos with progress tracking and error handling.
- **Auto Generation:** Generate multiple short-form videos from a single source.
- **Direct Upload:** Upload your generated shorts directly to YouTube Shorts.
- **Secure OAuth Login:** Sign up or log in securely with Google. Manage your YouTube channels and connect them with a single click.
- **Dashboard:** Manage all your videos and shorts in one place.
- **Pricing:** Simple, transparent pricing for every creator. [See Pricing](./pricing)
- **Contact:** Need help? [Contact us](./contact)

## Getting Started

1. **Clone the repo:**
   ```sh
   git clone https://github.com/yourusername/short_craft.git
   cd short_craft
   ```
2. **Install dependencies:**
   ```sh
   mix deps.get
   cd assets && npm install && cd ..
   ```
3. **Set up environment variables:**
   - `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REDIRECT_URI`
   - `YOUTUBE_API_KEY`, `OPENROUTER_API_KEY`, `GEMINI_API_KEY`
4. **Run the server:**
   ```sh
   mix phx.server
   ```
5. **Visit** [http://localhost:4000](http://localhost:4000)

## Pages

- **Home:** `/`
- **Register:** `/users/register`
- **Login:** `/users/log_in`
- **Pricing:** `/pricing`
- **Contact:** `/contact`
- **My Videos:** `/source_videos`

## License

MIT
