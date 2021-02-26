Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  # resources :home

  root 'home#index'
  post 'csr/create_csr'
  post 'csr/create_issue_in_another_account'
end
