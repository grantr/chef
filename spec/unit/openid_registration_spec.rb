#
# Author:: Adam Jacob (<adam@hjksolutions.com>)
# Copyright:: Copyright (c) 2008 HJK Solutions, LLC
# License:: GNU General Public License version 2 or later
# 
# This program and entire repository is free software; you can
# redistribute it and/or modify it under the terms of the GNU 
# General Public License as published by the Free Software 
# Foundation; either version 2 of the License, or any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::OpenIDRegistration, "initialize" do
  it "should return a new Chef::OpenIDRegistration object" do
    Chef::OpenIDRegistration.new.should be_kind_of(Chef::OpenIDRegistration)
  end
end

describe Chef::OpenIDRegistration, "set_password" do
  it "should generate a salt for this object" do
    oreg = Chef::OpenIDRegistration.new
    oreg.salt.should eql(nil)
    oreg.set_password("foolio")
    oreg.salt.should_not eql(nil)
  end
  
  it "should encrypt the password with the salt and the plaintext password" do
    oreg = Chef::OpenIDRegistration.new
    oreg.set_password("foolio")
    oreg.password.should_not eql(nil)
  end
end

describe Chef::OpenIDRegistration, "to_json" do
  it "should serialize itself as json" do
    oreg = Chef::OpenIDRegistration.new
    oreg.set_password("monkey")
    json = oreg.to_json
    %w{json_class chef_type name salt password validated}.each do |verify|
      json.should =~ /#{verify}/
    end
  end
end

describe Chef::OpenIDRegistration, "from_json" do
  it "should serialize itself as json" do
    oreg = Chef::OpenIDRegistration.new()
    oreg.name = "foobar"
    oreg.set_password("monkey")
    oreg_json = oreg.to_json
    nreg = JSON.parse(oreg_json)
    nreg.should be_a_kind_of(Chef::OpenIDRegistration)
    %w{name salt password validated}.each do |verify|
      nreg.send(verify.to_sym).should eql(oreg.send(verify.to_sym))
    end
  end
end

describe Chef::OpenIDRegistration, "list" do  
  before(:each) do
    @mock_couch = mock("Chef::CouchDB")
    @mock_couch.stub!(:list).and_return({
      "rows" => [
        {
          "value" => "a",
          "key"   => "avenue"
        }
      ]
    })
    Chef::CouchDB.stub!(:new).and_return(@mock_couch)
  end
  
  it "should retrieve a list of nodes from CouchDB" do
    Chef::OpenIDRegistration.list.should eql(["avenue"])
  end
  
  it "should return just the ids if inflate is false" do
    Chef::OpenIDRegistration.list(false).should eql(["avenue"])
  end
  
  it "should return the full objects if inflate is true" do
    Chef::OpenIDRegistration.list(true).should eql(["a"])
  end
end

describe Chef::OpenIDRegistration, "load" do
  it "should load a registration from couchdb by name" do
    @mock_couch = mock("Chef::CouchDB")
    Chef::CouchDB.stub!(:new).and_return(@mock_couch)
    @mock_couch.should_receive(:load).with("openid_registration", "coffee").and_return(true)
    Chef::OpenIDRegistration.load("coffee")
  end
end

describe Chef::OpenIDRegistration, "destroy" do
  it "should delete this registration from couchdb" do
    @mock_couch = mock("Chef::CouchDB")
    @mock_couch.should_receive(:delete).with("openid_registration", "bob", 1).and_return(true)
    Chef::CouchDB.stub!(:new).and_return(@mock_couch)
    reg = Chef::OpenIDRegistration.new
    reg.name = "bob"
    reg.couchdb_rev = 1
    reg.destroy
  end
end

describe Chef::OpenIDRegistration, "save" do
  before(:each) do
    @mock_couch = mock("Chef::CouchDB")
    Chef::CouchDB.stub!(:new).and_return(@mock_couch)
    @reg = Chef::OpenIDRegistration.new
    @reg.name = "bob"
    @reg.couchdb_rev = 1
  end
  
  it "should save the registration to couchdb" do
    @mock_couch.should_receive(:store).with("openid_registration", "bob", @reg).and_return({ "rev" => 33 }) 
    @reg.save
  end
  
  it "should store the new couchdb_rev" do
    @mock_couch.stub!(:store).with("openid_registration", "bob", @reg).and_return({ "rev" => 33 }) 
    @reg.save
    @reg.couchdb_rev.should eql(33)
  end
end

describe Chef::OpenIDRegistration, "create_design_document" do
  it "should create our design document" do
    mock_couch = mock("Chef::CouchDB")
    mock_couch.should_receive(:create_design_document).with("registrations", Chef::OpenIDRegistration::DESIGN_DOCUMENT)
    Chef::CouchDB.stub!(:new).and_return(mock_couch)
    Chef::OpenIDRegistration.create_design_document
  end
end

describe Chef::OpenIDRegistration, "has_key?" do
  it "should check with CouchDB for a registration with this key" do
    @mock_couch = mock("Chef::CouchDB")
    @mock_couch.should_receive(:has_key?).with("openid_registration", "bob").and_return(true)
    Chef::CouchDB.stub!(:new).and_return(@mock_couch)
    Chef::OpenIDRegistration.has_key?("bob")
  end
end

