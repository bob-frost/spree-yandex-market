Deface::Override.new( :virtual_path => "spree/admin/shared/_menu",
                      :name => "converted_admin_tabs",
                      :insert_bottom => "[data-hook='admin_tabs']",
                      :text => "<%=  tab(:yandex_market, :icon => 'icon-shopping-cart', :route => 'admin_yandex_market_settings' )  %>",
                      :disabled => false
                    )
