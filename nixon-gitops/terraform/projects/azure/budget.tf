module "azure_budget" {
  source          = "../../modules/azure_budget"
  name            = "monthly-subscription-budget"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget.amount
  contact_emails  = var.monthly_budget.contact_emails
  start_date      = var.monthly_budget.start_date
}
