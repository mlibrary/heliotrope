HydraEditor::Engine.routes.draw do
  resources :records, only: [:new, :edit, :create, :update], constraints: { id: /[a-zA-Z0-9_.:\-\/%]+/ }
end
