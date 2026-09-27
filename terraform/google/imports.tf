# Everything in this root existed before Terraform did. These blocks adopt it
# instead of creating it: on a checkout with no state, `plan` reports
# "N to import, 0 to add, 0 to change, 0 to destroy", and anything other than
# 0/0/0 means the declaration drifted from the live project.
#
# They stay after the first apply: once a resource is in the state its import
# block is a no-op, and a fresh machine (the state is local, never committed)
# adopts the project again the same way.

import {
  to = google_project.goalgetter
  id = var.project_id
}

import {
  for_each = local.used_services
  to       = google_project_service.used[each.key]
  id       = "${var.project_id}/${each.key}"
}

import {
  to = google_apikeys_key.gemini
  id = "projects/${var.project_id}/locations/global/keys/f65894fd-2e8f-4ef2-a82d-982bc54c81fd"
}

import {
  to = google_apikeys_key.youtube
  id = "projects/${var.project_id}/locations/global/keys/9a116654-57e6-4c70-adf0-bef6e604cda1"
}
