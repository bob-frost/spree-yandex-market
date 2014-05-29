# -*- coding: utf-8 -*-
require 'nokogiri'

module Export
  class YandexMarketExporter
    include Spree::Core::Engine.routes.url_helpers
    attr_accessor :host, :currencies

    def helper
      @helper ||= ApplicationController.helpers
    end
    
    def export
      @config = Spree::YandexMarket::Config.instance
      @host = ActionController::Base.asset_host = Spree::Config.site_url
      
      @currencies = @config.preferred_currency.split(';').map{|x| x.split(':')}
      @currencies.first[1] = 1
      
      # Nokogiri::XML::Builder.new({ :encoding =>"utf-8"}, SCHEME) do |xml|
      Nokogiri::XML::Builder.new(:encoding =>"utf-8") do |xml|
        xml.doc.create_internal_subset('yml_catalog',
          nil,
          "shops.dtd"
        )

        xml.yml_catalog(:date => Time.now.to_s(:ym)) {
          
          xml.shop { # описание магазина
            xml.name    @config.preferred_short_name
            xml.company @config.preferred_full_name
            xml.url     path_to_url('')
            
            xml.currencies { # описание используемых валют в магазине
              @currencies && @currencies.each do |curr|
                opt = {:id => curr.first, :rate => curr[1] }
                opt.merge!({ :plus => curr[2]}) if curr[2] && ["CBRF","NBU","NBK","CB"].include?(curr[1])
                xml.currency(opt)
              end
            }        
            
            xml.categories { # категории товара
              Spree::Taxon.categories_root.self_and_descendants.each do |cat|
                @cat_opt = { :id => cat.id }
                @cat_opt.merge!({ :parentId => cat.parent_id}) unless cat.parent_id.blank?
                xml.category(@cat_opt){ xml  << cat.name }
              end
            }

            # Cтоимость доставки для региона, в котором расположен магазин
            if @config.preferred_local_delivery_cost.present?
              xml.local_delivery_cost @config.preferred_local_delivery_cost
            end
            
            xml.offers { # список товаров
              products = Spree::Product.visible.where(:export_to_yandex_market => true).group("#{Spree::Product.table_name}.id")
              products.find_each do |product|
                unless product.brand.blank? || product.category.blank? || (@config.preferred_wares == 'can_stock' && !product.master.can_stock?)
                  offer(xml, product)
                end
              end
            }
          }
        } 
      end.to_xml
      
    end
    
    
    private
    
    def path_to_url(path)
      "http://#{@host.sub(%r[^http://],'')}/#{path.sub(%r[^/],'')}"
    end
    
    def offer(xml,product)
      opt = { :type => 'vendor.model', :id => product.id, :available => (product.master.total_on_hand > 0) }
      xml.offer(opt) {
        xml.url                     product_url(product, :host => @host)
        xml.price                   product.price
        xml.currencyId              @currencies.first.first
        xml.categoryId              product.category_id
        if image = product.images.first
          xml.picture               path_to_url(image.attachment.url(:product, false))
        end
        xml.delivery                true
        xml.vendor                  product.brand_name
        xml.model                   product.name
        if product.description.present?
          xml.description           product.description
        end
        if product.warranty.present? && product.warranty > 0
          xml.manufacturer_warranty product.warranty
        end

        product_properties = product.product_properties.includes(:property)
        product_properties = product.category.filter_displayed_product_properties(product_properties, 'product_show')
        product_properties.each do |pp|
          xml.param pp.value, {:name => pp.property_name}
        end
      }
    end
    
  end
end
