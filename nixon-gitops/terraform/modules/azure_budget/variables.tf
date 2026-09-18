variable "name" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "amount" {
  type = number
}

variable "contact_emails" {
  type = list(string)
}

variable "start_date" {
  type = string
}
