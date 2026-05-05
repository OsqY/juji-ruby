# Pin npm packages by running ./bin/importmap

pin "application"
pin "@rails/actioncable", to: "@rails--actioncable.js" # @8.1.300
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "lucide" # @0.564.0
pin "html2canvas" # @1.4.1
pin "chart.js" # @4.5.1
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4
pin "roughjs" # @4.6.6
