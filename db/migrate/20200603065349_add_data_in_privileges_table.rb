class AddDataInPrivilegesTable < ActiveRecord::Migration[5.1]
  def self.up
    Privilege.create(:privilege_name=>'Roles & Privileges')
    Privilege.create(:privilege_name=>'Send Push')
    Privilege.create(:privilege_name=>'Restaurant Documents')
    Privilege.create(:privilege_name=>'All Company')
    Privilege.create(:privilege_name=>'Requested Company')
    Privilege.create(:privilege_name=>'Rejected Company')
    Privilege.create(:privilege_name=>'Add New Company')
    Privilege.create(:privilege_name=>'Delivery Charges')
    Privilege.where('id =1').update(privilege_name: 'Create user')
    Privilege.where('id =2').update(privilege_name: 'Approve users')
    Privilege.where('id =22').update(privilege_name: 'Admin Documents')
    Privilege.where('id =23').update(privilege_name: 'All Notifications')
    
  end
end
