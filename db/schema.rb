Sequel.migration do
  change do
    create_table(:active_admin_comments) do
      primary_key :id, :type=>:Bignum
      column :namespace, "character varying"
      column :body, "text"
      column :resource_type, "character varying"
      column :resource_id, "bigint"
      column :author_type, "character varying"
      column :author_id, "bigint"
      column :created_at, "timestamp(6) without time zone", :null=>false
      column :updated_at, "timestamp(6) without time zone", :null=>false
      
      index [:author_type, :author_id], :name=>:index_active_admin_comments_on_author
      index [:namespace], :name=>:index_active_admin_comments_on_namespace
      index [:resource_type, :resource_id], :name=>:index_active_admin_comments_on_resource
    end
    
    create_table(:admin_users) do
      primary_key :id, :type=>:Bignum
      column :email, "character varying", :default=>"", :null=>false
      column :encrypted_password, "character varying", :default=>"", :null=>false
      column :reset_password_token, "character varying"
      column :reset_password_sent_at, "timestamp without time zone"
      column :remember_created_at, "timestamp without time zone"
      column :created_at, "timestamp(6) without time zone", :null=>false
      column :updated_at, "timestamp(6) without time zone", :null=>false
      
      index [:email], :name=>:index_admin_users_on_email, :unique=>true
      index [:reset_password_token], :name=>:index_admin_users_on_reset_password_token, :unique=>true
    end
    
    create_table(:ar_internal_metadata) do
      column :key, "character varying", :null=>false
      column :value, "character varying"
      column :created_at, "timestamp(6) without time zone", :null=>false
      column :updated_at, "timestamp(6) without time zone", :null=>false
      
      primary_key [:key]
    end
    
    create_table(:schema_info) do
      column :version, "integer", :default=>0, :null=>false
    end
    
    create_table(:schema_migrations) do
      column :filename, "text"
    end
    
    create_table(:subscribers) do
      column :service, "text", :null=>false
      column :chat_id, "text", :null=>false
      column :name, "text"
      column :parser, "text"
      column :resource, "text"
      column :last_text, "text"
      column :opts, "jsonb", :default=>Sequel::LiteralString.new("'{}'::jsonb")
      
      primary_key [:service, :chat_id]
    end
    
    create_table(:users) do
      primary_key :id, :type=>:Bignum
      column :email, "character varying", :default=>"", :null=>false
      column :encrypted_password, "character varying", :default=>"", :null=>false
      column :reset_password_token, "character varying"
      column :reset_password_sent_at, "timestamp without time zone"
      column :remember_created_at, "timestamp without time zone"
      column :created_at, "timestamp(6) without time zone", :null=>false
      column :updated_at, "timestamp(6) without time zone", :null=>false
      
      index [:email], :name=>:index_users_on_email, :unique=>true
      index [:reset_password_token], :name=>:index_users_on_reset_password_token, :unique=>true
    end
  end
end
              Sequel.migration do
                change do
                  self << "SET search_path TO \"$user\", public"
                  self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20211128022411_devise_create_users.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20211128022544_devise_create_admin_users.rb')"
self << "INSERT INTO \"schema_migrations\" (\"filename\") VALUES ('20211128022546_create_active_admin_comments.rb')"
                end
              end
