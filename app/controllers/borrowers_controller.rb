class BorrowersController < ApplicationController
  before_action :set_borrower, only: %i[ show edit update destroy ]

  # GET /borrowers or /borrowers.json
  def index
    @borrowers = Borrower.order(created_at: :desc).page(params[:page]).per(5)
  end

  # GET /borrowers/1 or /borrowers/1.json
  def show
  end

  # GET /borrowers/new
  def new
    @borrower = Borrower.new
  end

  # GET /borrowers/1/edit
  def edit
  end

  # POST /borrowers or /borrowers.json
  def create
    @borrower = Borrower.new(borrower_params)
    @borrower.created_by = Current.user
    @borrower.updated_by = Current.user

    respond_to do |format|
      if @borrower.save
        format.html { redirect_to @borrower, notice: "Borrower was successfully created." }
        format.json { render :show, status: :created, location: @borrower }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @borrower.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /borrowers/1 or /borrowers/1.json
  def update
    @borrower.updated_by = Current.user
    respond_to do |format|
      if @borrower.update(borrower_params)
        format.html { redirect_to @borrower, notice: "Borrower was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @borrower }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @borrower.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /borrowers/1 or /borrowers/1.json
  def destroy
    if @borrower.loans.exists?
      respond_to do |format|
        format.html { redirect_to @borrower, alert: "Cannot delete borrower with existing loans. #{@borrower.loans.count} loan(s) found.", status: :see_other }
        format.json { render json: { error: "Cannot delete borrower with existing loans" }, status: :unprocessable_entity }
      end
    else
      @borrower.destroy!

      respond_to do |format|
        format.html { redirect_to borrowers_path, notice: "Borrower was successfully deleted.", status: :see_other }
        format.json { head :no_content }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_borrower
      @borrower = Borrower.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def borrower_params
      params.expect(borrower: [ :name, :email, :phone, :address ])
    end
end
