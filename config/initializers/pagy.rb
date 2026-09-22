# Page size shared by the paginated chat list (drawer) and message log (chat
# page). Pagy freezes Pagy::DEFAULT, so the override goes through Pagy::OPTIONS,
# which every `pagy` call merges in.
Pagy::OPTIONS[:limit] = 50
