# coding: UTF-8

require 'spec_helper'

describe Spree::ProductGroup do

  context "validations" do
    it { should validate_presence_of(:name) }
    it { should have_many(:product_scopes).dependent(:destroy) }
    it { should have_valid_factory(:product_group) }
  end

  describe '#dynamic_products' do

    context 'with a scope named with_ids' do
      let!(:product_1) { Factory(:product) }
      let!(:product_2) { Factory(:product) }
      let!(:product_3) { Factory(:product) }
      let!(:product_group) do
        product_group = Factory(:product_group, :name => "With IDs")
        product_group.product_scopes.create!(:name => "with_ids", :arguments => ["#{product_1.id},#{product_2.id}"])
        product_group
      end

      it 'should return proper products' do
        product_group.dynamic_products.to_a.should eql([product_1, product_2])
      end

    end

  end

  describe '#from_route' do
    context "wth valid scopes" do
      before do
        subject.from_route(["master_price_lte", "100", "in_name_or_keywords", "Ikea", "ascend_by_master_price"])
      end

      it "sets one ordering scope" do
        subject.product_scopes.select(&:is_ordering?).length.should == 1
      end

      it "sets two non-ordering scopes" do
        subject.product_scopes.reject(&:is_ordering?).length.should == 2
      end
    end

    context 'with an invalid product scope' do
      before do
        subject.from_route(["master_pri_lte", "100", "in_name_or_kerds", "Ikea"])
      end

      it 'sets no product scopes' do
        subject.product_scopes.should be_empty
      end
    end

  end

  # Regression test for #774
  context "Regression test for #774" do
    let!(:property) { Factory(:property, :name => "test") }
    let!(:product) do
      product = Factory(:product)
      product.properties << property
      product
    end

    let!(:product_group) do
     product_group = Factory(:product_group, :name => "Not sports")
     product_group.product_scopes.create!(:name => "with_property", :arguments => ["test"])
     product_group
    end

    it "updates a product group when a property is deleted" do
      product_group.products.should include(product)
      property.destroy
      product_group.products(true).should_not include(product)
    end

  end

  context "correct permalink" do

    # Regression test for issue raised here: https://github.com/spree/spree/pull/847#issuecomment-3048822
    it "should handle Chinese characters correctly" do
      product_group = Spree::ProductGroup.create(:name => "你好")
      product_group.permalink.should == "ni-hao"
    end

    it "should return stored value when name changes" do
      product_group = Spree::ProductGroup.create(:name => 'Pirate Essentials')
      product_group.name = 'Pirate Specials'
      product_group.save!
      product_group.name.should == 'Pirate Specials'
      product_group.permalink.should == 'pirate-essentials'
    end

  end

  describe 'Regression test for #11' do

    context 'with a scope named with_ids' do
      let!(:product_1) { Factory(:product) }
      let!(:product_2) { Factory(:product) }
      let!(:product_3) { Factory(:product) }
      let!(:product_group) do
        product_group = Factory(:product_group, :name => "With IDs")
        product_group.product_scopes.create!(:name => "with_ids", :arguments => ["#{product_1.id},#{product_2.id}"])
        product_group
      end

      context 'include?' do

        it 'should return false for products not in the product group' do
          product_group.include?(product_3).should == false
        end

        it 'should return true for products in the product group' do
          product_group.include?(product_2).should == true
        end

      end

      it 'should return proper products after another product has been updated ' do
        product_group.update_memberships
        product_3.save
        product_group.products.count.should == 2
      end

    end

  end

end
