ActiveAdmin.register Group do

  permit_params :service, :chat_id, :name, :last_message

end
