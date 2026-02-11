# Entry point
pin "application", preload: true

# Hotwire
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true

# Controllers
pin_all_from "app/javascript/controllers", under: "controllers"
