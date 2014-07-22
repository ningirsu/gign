class SuppliesController < ApplicationController
  before_action :set_supply, only: [:show, :edit, :update, :destroy, :loan, :upload]

  # GET /supplies
  # GET /supplies.json
  def index
    @supplies = Supply.all
  end

  # GET /supplies/1
  # GET /supplies/1.json
  def show
  end

  # GET /supplies/new
  def new
    @supply = Supply.new
  end

  # GET /supplies/1/edit
  def edit
  end

  # POST /supplies
  # POST /supplies.json
  def create
    @supply = Supply.new(supply_params)

    respond_to do |format|
      if @supply.save
        format.html { redirect_to @supply, flash: {notice: 'Supply was successfully created.'} }
        format.json { render action: 'show', status: :created, location: @supply }
      else
        format.html { render action: 'new' }
        format.json { render json: @supply.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /supplies/1
  # PATCH/PUT /supplies/1.json
  def update
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
    @supply.destroy
    respond_to do |format|
      format.html { redirect_to supplies_url }
      format.json { head :no_content }
    end
  end

  def loan
    if current_user.active_basket.loan!(@supply)
      flash[:notice] = t("loan.correctly_add_to_basket")
      respond_to do |format|
        format.html {redirect_to @supply}
        format.js
      end
    else
      flash[:error] = t("errors.supply.loan.failed")
      respond_to do |format|
        format.html{ render action: 'show'}
      end
    end
  end

  def upload
    if !params[:image][:url].blank?
      if Image.upload_url(params[:image][:url], @supply, params[:image][:name])
        flash[:notice] = t("notice.supply.upload.success_url")
      else
        flash[:error] = t("errors.supply.upload.failed_url")
      end
    elsif !params[:image][:file].blank?
      if Image.upload_file(params[:image][:file], @supply, params[:image][:name])
        flash[:notice] = t("notice.supply.upload.success_file")
      else
        flash[:error] = t("errors.supply.upload.failed_file")
      end
    else
      flash[:error] = t("errors.supply.upload.no_params")
    end
    respond_to do |format|
      format.html{ redirect_to @supply}
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
