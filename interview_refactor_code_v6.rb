# Tips:
# 這份檔案裡面包含各種邏輯錯誤 / 安全性問題, Typo 等等, 請當成是在 review 一份年久失修的 Production code (B2C)
# 請在這個檔案內留下修改意見以及修改過的 code

# app/models/xx.rb

class User < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，改為 class User < ApplicationRecord
  has_one :cart
  has_one :orders
  # orders會有很多筆所以association要改成 has_many :orders

  # 下方有FavProducts Model，推測為user與product的join table，用來記錄user按讚商品，應加上與product的多對多關聯 
  has_many :fav_products
  has_many :products, through: :fav_products
end

class Product < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，改為 class User < ApplicationRecord
  has_one :stock

  # 下方有FavProducts Model，推測為user與product的join table，用來記錄user按讚商品，應加上與user的多對多關聯
  has_many :fav_products
  has_many :users, through: :fav_products
  # 一個商品會對應到多個商品項目，加上一對多關聯
  has_many :cart_items
end

class Cart < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，改為 class User < ApplicationRecord
  belongs_to :user
  # 一台購物車會生成一筆訂單，加上與訂單的一對一關聯
  has_one :order
   # 一台購物車會有很多商品項目，加上與商品項目的一對多關聯
  has_many :cart_items

  # 新增購物車狀態，確認是否生成訂單
  enum cart_type:[:checked, :unchecked]
end

class CartItems < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，且Ｍodel名稱應為大寫單數，改為 class CartItem < ApplicationRecord
  belongs_to :cart
  # 一個商品項目會對應到一個商品，加上與商品的關聯
  has_one :product
end

class Order < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，改為 class Order < ApplicationRecord
  belongs_to :user
  # 一筆訂單會對應到一台購物車資料，加上與購物車的一對一關聯
  belongs_to :cart
  # 新增訂單狀態
  enum cart_type: [:not_paid, :paid, :cancelled]
end

class FavProducts < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，且Ｍodel名稱應為大寫單數，改為 class FavProduct < ApplicationRecord
  belongs_to :user
  # 此為join table 要加上與product的關聯
  belongs_to :product
end

class User < ActiveRecord::Base
  # 此處應繼承自ApplicationRecord，不會直接繼承ActiveRecord::Base，改為 class User < ApplicationRecord
  # 省略各種 code

  def send_reset_password_email
    # pass
  end
end

class PasswordsController < Devise::PasswordsController
  # 參照devise文件用法，此處應該為class Users::PasswordsController < Devise::PasswordsController
 

  def reset_password
    email = params[:email]
    user = User.find_By(email: email)
    # 沒有find_By方法，改成 user = User.find_by(email: email)

    if @redis.get('forgot_password')
      redirect_to '/login?error=too_often'
      # 依照RESTful慣例，此處路徑應修正為'/users/login?error=too_often'，, 加上notice: "密碼輸入錯誤多次，請再次確認"
      # 不過不建議直接把params串在url，更好的作法可能是在routes.rb定義好路徑，直接使用Prefix，如often_error_login_user_path
      
    if user.blank?
      # 依照if...else判斷式寫法，此處應改成 elsif user.blank?
      redirect_to '/login?error=wrong_xxxxxx'
      # 依照RESTful慣例，此處路徑應修正為'/users/login?error=wrong_email_address'，加上notice: "請輸入正確信箱"
      # 不過不建議直接把params串在url，更好的作法可能是在routes.rb定義好路徑，直接使用Prefix，如wrong_email_error_login_user_path

    else
      user.send_reset_password_email
      redirect_to '/'
    end

    @redis.set('forgot_password', Time.current.utc, nx: true)
    @redis.expire('forgot_password', 10)
  end


end

# app/test/product_controller.rb

module Test
  class ProductController < ApplicationController
    before_action :authenticate_user

    def my_cart
      @cart = Cart.find_by(id: params[:id])
    end

    def add_to_cart
      product = Product.find_by(id: params[:id]).stock
      product.stock.update(value: (product.stock.value - params[:number]))
      # product變數已知有多少stock，此處應改成product.update(value: (product.value - params[:number]))
      @cart ||= Cart.first_or_create(user_id: current_user.id)
      @cart.cart_items.create(product_id: product.id, quantity: params[:number])
    end

    def add_fav_products
      current_user.fav_products.create(product_id: params[:id], note: params[:note])
      @success_message = "<b>Success!</b> note: #{params[:note]}"
    end

    def my_fav_products
      @products = current_user.fav_products
    end

    def create_order
      cart = Cart.find_by(id: params[:id])

      @order = Order.create(
        user_id: current_user.id,
        items: cart.cart_items,
        email: current_user.email
      )
    end

    def my_orders
      @orders = current.user.orders
      # 改成 @orders = current＿user.orders
    end

    def my_order_detail
      @order = Order.find_by(id: params[:order_id])
    end
  end
end

-------------View------------

# app/views/add_fav_products.html.slim

div=@success_message.html_safe

# app/views/my_fav_products.html.slim

@products.find_each do |product|
  # 變數前方加上"-"，改成- @products.find_each do |product|
  table
    tr
      td = product.name
      td = "Note: <br> #{product.note}".html_safe

# app/views/my_cart.html.slim

@cart.cart_items.find_each do |item|
  # 變數前方加上"-"，改成- @cart.cart_items.find_each do |item|
  table
    tr
      td=item.name
      td=item.quantity

# app/views/add_to_cart.html.slim
  div Success!

# app/views/create_order.html.slim
  div Success!

# app/views/my_orders.html.slim

@orders.find_each do |order|
  # 變數前方加上"-"，改成- @orders.find_each do |order|
  table
    tr
      td=order.id
      td=order.create_at

# app/views/my_order_detail.html.slim

table
  tr
    td=@order.id
    td=@order.email

@order.items.map do |item|
  # 變數前方加上"-"，不需要使用.map來產生新元素陣列，使用.find_each，改成- @orders.find_each do |item|
  table
    tr
      td=item.name
      td=item.quantity