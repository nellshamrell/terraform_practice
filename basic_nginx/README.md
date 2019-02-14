# Basic NGINX Example

Create a Terraform config that:
* Spins up a t2.micro AWS instance
* Allows ssh, http, and https connectivity to that instance
* Installs nginx
* Copies a template (which includes displaying a welcome message that is set by variable) for index.html to /var/www/html/index.html