module "azure_budget" {
  source          = "git::https://github.com/joshua-nixon/terraform-modules.git//azure_budget?ref=main"
  name            = "monthly-subscription-budget"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = var.monthly_budget.amount
  contact_emails  = var.monthly_budget.contact_emails
  start_date      = var.monthly_budget.start_date
}
