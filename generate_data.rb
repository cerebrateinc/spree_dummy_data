require 'set'
require 'faker'
require 'curb'
require 'json'

# Initialize Store URL and Token
STORE_URL= "http://mega-mart-1516.spree.mx" #"http://majestic-cart-3030.spree.mx" #"http://monster-basket-2205.spree.mx"
TOKEN= "7a5746670f7d2c7b44c478b304520ea9cb1faf9f9a1384d0"  #"50142d8cf796ec97610e98136a0b4c586eab32278c1267a5"#"0d756afff13bc0357b2348de38ed8e50ebcb9869ed8ddd1b"


while(true)
	# Get all available variants
	get_variants_api = "/api/variants.json"
	request = Curl.get("#{STORE_URL}#{get_variants_api}?token=#{TOKEN}")
	unless request.response_code.to_i == 200
		puts "\nUnable to get variants"
		exit(0)
	end

	variants = JSON.parse(request.body_str) 
	variant_ids = variants["variants"].map { |v| v["id"] }


	# Create an empty order
	create_order_api = "/api/orders.json"
	request = Curl.post("#{STORE_URL}#{create_order_api}") do |http|
		http.headers['X-Spree-Token'] = TOKEN
	end
	puts "\nCreating order"
	
	# Successful create API call returns 201 (http://guides.spreecommerce.com/api/summary.html#rules)
	if request.response_code.to_i == 201
		puts "\nOrder created successfully"
	else
		puts "\nUnable to create a new order! Exiting."
		exit(0)
	end
	order = JSON.parse(request.body_str) 
	order_number = order["number"]
	puts "\nORDER NUMBER = #{order_number}"

	# Create Line Items
	for i in 0..Random.rand(1..3)
		line_items_api = "/api/orders/#{order_number}/line_items.json"
		request = Curl::Easy.http_post("#{STORE_URL}#{line_items_api}",
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
   	end
	
	# PUT /api/checkouts/:number/next.json


	# Update Customer Name and Address
	abandon_cart = Random.rand() < 0.3 
	if abandon_cart
		puts "\nAbandoning cart!"
	else
		puts "\nUpdating order with customer information"
		customer_info_api = "/api/checkouts/#{order_number}.json"
		customer_information = {
			"firstname" => Faker::Name.first_name,
			"lastname" => Faker::Name.last_name,
			"address1" => Faker::Address.street_address,
			"city" => Faker::Address.city,
			"phone" => Faker::PhoneNumber.cell_phone,
			"zipcode" => Faker::Address.zip_code,
			"state_id" => 48,
			"country_id" => 49	
		}

		order_payload = {
			"order" => {
				"bill_address_attributes" => customer_information,
				"ship_address_attributes" => customer_information,
			}
		}

		request = Curl.put("#{STORE_URL}#{customer_info_api}", order_payload.to_json) do |http|
			http.headers['X-Spree-Token'] = TOKEN
		end
		
		if request.response_code == 200
			puts "\nAddress information updated!"
		else
			puts "\nUnable to update address information"
		end
	end

	# Update Billing information
	# TODO
	sleep_for = Random.rand(5..15)
	puts "\nSleeping for #{sleep_for}s"
	sleep(sleep_for)
end
