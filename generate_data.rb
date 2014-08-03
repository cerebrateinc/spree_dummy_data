require 'set'
require 'faker'
require 'curb'
require 'json'

# Initialize Store URL and Token
STORE_URL="http://monster-basket-2205.spree.mx"
TOKEN="0d756afff13bc0357b2348de38ed8e50ebcb9869ed8ddd1b"


# Get all available variants
GET_VARIANTS_API = "/api/variants.json"
request = Curl.get("#{STORE_URL}#{GET_VARIANTS_API}?token=#{TOKEN}")
unless request.response_code.to_i == 200
	puts "\nUnable to get variants"
	exit(0)
end

variants = JSON.parse(request.body_str) 
variant_ids = variants["variants"].map { |v| v["id"] }


# Create an empty order
CREATE_ORDER_API = "/api/orders.json"
request = Curl.post("#{STORE_URL}#{CREATE_ORDER_API}") do |http|
	http.headers['X-Spree-Token'] = TOKEN
end
puts "create order"
puts request.body_str

# Successful create API call returns 201 (http://guides.spreecommerce.com/api/summary.html#rules)
if request.response_code.to_i == 201
	puts "\nOrder created successfully"
else
	puts "\nUnable to create a new order! Exiting"
	exit(0)
end
order = JSON.parse(request.body_str) 
order_number = order["number"]
puts "\nORDER NUMBER = #{order_number}"



# Create Line Items
LINE_ITEMS_API = "/api/orders/#{order_number}/line_items.json"
request = Curl::Easy.http_post("#{STORE_URL}#{LINE_ITEMS_API}",
                         Curl::PostField.content('line_item[variant_id]', "#{Random.rand(variant_ids.min..variant_ids.max)}"),
                         Curl::PostField.content('line_item[quantity]', "#{Random.rand(1..4)}")) do |http|
	http.headers['X-Spree-Token'] = TOKEN
end

# Successful update API call returns 201 (http://guides.spreecommerce.com/api/summary.html#rules)
if request.response_code.to_i == 201
	puts "\nLine item created successfully"
else
	puts "\nUnable to create line item! Exiting"
	exit(0)
end
line_item = JSON.parse(request.body_str) 
puts "\nLINE ITEM = #{line_item}"

# PUT /api/checkouts/:number/next.json


# Update Customer Name and Address
abandon_cart = Random.rand() > 0.3 
if abandon_cart
	puts "\nAbandoning cart!"
else
	puts "\nUpdating order with customer information"
	CUSTOMER_INFO = "/api/checkouts/#{order_number}.json"
	customer_information = {
		"firstname" => "John",
		"lastname" => "Doe",
		"address1" => "7735 Old Georgetown Road",
		"city" => "Bethesda",
		"phone" => "3014445002",
		"zipcode" => "20814",
		"state_id" => 48,
		"country_id" => 49	
	}

	order_payload = {
		"order" => {
			"bill_address_attributes" => customer_information,
			"ship_address_attributes" => customer_information,
		}
	}

	request = Curl.put("#{STORE_URL}#{CUSTOMER_INFO}", order_payload.to_json) do |http|
		http.headers['X-Spree-Token'] = TOKEN
	end
	
	puts "\n#{request.response_code.to_i}"
	unless request.response_code == 201
		puts request.body_str
	end
end

# Update Billing information
# TODO
