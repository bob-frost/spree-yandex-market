Deface::Override.new( :virtual_path => "spree/admin/shared/_menu",
                      :name => "converted_admin_tabs",
                      :insert_bottom => "[data-hook='admin_tabs']",
                      :text => "<%=
                        if can? :read, :yandex_market_settings
                          tab(:yandex, :route => 'admin_yandex_market_settings')
                        end
                        %>"
                    )

Deface::Override.new( :virtual_path => "spree/admin/products/_form",
                      :name => "product_form_export_to_yandex_market_field",
                      :insert_bottom => "[data-hook='admin_product_form_left']",
                      :partial => "spree/admin/products/export_to_yandex_market_field"
                    )
