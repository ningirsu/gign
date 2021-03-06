# == Schema Information
#
# Table name: supplies
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  price       :integer          default(0)
#  description :text(65535)
#  loanable    :boolean          default(TRUE)
#  created_at  :datetime
#  updated_at  :datetime
#  user_id     :integer
#

class SuppliesController < ApplicationController
  before_action :set_supply, only: [:show, :update, :destroy, :loan, :add_copy]

  before_action do
    add_breadcrumb_if_can t('activerecord.models.supply', count: 2), supplies_path, :index, Supply
  end
  before_action only: [:show] do
    add_breadcrumb_if_can @supply.name, supply_path(@supply), :show, @supply
  end

  # GET /supplies
  # GET /supplies.json
  def index
    session[:display] = params[:display] if params[:display]
    session[:loanable] = params[:loanable] if params[:loanable]

    if can? :manage, Supply
      if session[:loanable] == '1'
        @supplies = Supply.loanables.includes(:translations, :supply_copies)
      elsif session[:loanable] == '0'
        @supplies = Supply.not_loanables.includes(:translations, :supply_copies)
      else
        @supplies = Supply.all.includes(:translations, :supply_copies)
      end

    else
      @supplies = Supply.loanables.includes(:translations, :supply_copies)
    end
  end

  # GET /supplies/1
  # GET /supplies/1.json
  def show
  end

  # POST /supplies
  # POST /supplies.json
  def create
    authorize! :create, Supply
    @supply = Supply.new(supply_params)
    @supply.creator = current_user

    respond_to do |format|
      if @supply.save
        format.html { redirect_to supplies_path, flash: { notice: 'Supply was successfully created.' } }
        format.json { render action: 'show', status: :created, location: @supply }
      else
        format.html { render action: 'index' }
        format.json { render json: @supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /supplies/1
  # PATCH/PUT /supplies/1.json
  def update
    authorize! :edit, @supply
    respond_to do |format|
      if @supply.update(supply_params)
        format.html { redirect_to @supply, notice: 'Supply was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /supplies/1
  # DELETE /supplies/1.json
  def destroy
    authorize! :destroy, @supply
    @supply.destroy
    respond_to do |format|
      format.html { redirect_to supplies_url }
      format.json { head :no_content }
    end
  end

  def loan
    authorize! :loan, @supply
    if current_user.active_basket.ask_for_loan(@supply)
      flash[:notice] = t('notice.supply.loan.success')
      respond_to do |format|
        format.html { redirect_to @supply }
        format.js
      end
    else
      flash[:error] = t('errors.supply.loan.failed')
      respond_to do |format|
        format.html { render action: 'show' }
        format.js
      end
    end
  end

  def add_copy
    authorize! :add_copy, @supply
    if @supply.new_copy!
      flash[:notice] = t('notice.supply.add_copy.success')
    else
      flash[:error] = t('errors.supply.add_copy.failed')
    end
    respond_to do |format|
      format.html { redirect_to @supply }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_supply
    @supply = Supply.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def supply_params
    params.require(:supply).permit(:name, :price, :loanable, :description)
  end
end
