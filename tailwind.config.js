module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/controllers/**/*.rb",
    "./app/javascript/**/*.js"
  ],
  safelist: [
    'bg-cyan-500',
    'bg-red-500', 
    'text-white',
    'text-gray-600',
    'font-bold',
    'text-4xl',
    'py-2',
    'px-4',
    'rounded',
    'bg-gray-100',
    'mt-28',
    'px-5',
    'container',
    'mx-auto',
    'flex',
    'min-h-screen',
    // Nuevas clases para el reloj
    'bg-white',
    'rounded-lg',
    'shadow-md',
    'p-4',
    'text-center',
    'text-lg',
    'font-semibold',
    'text-md',
    'text-sm',
    'bg-blue-200',
    'space-x-4',
    'flex-1',
    'py-3',
    'px-6',
    'space-y-6'
  ],
  theme: {
    extend: {
      fontFamily: {
        'roboto-mono': ['"Roboto Mono"', 'monospace'],
      }
    },
  },
  plugins: [],
}