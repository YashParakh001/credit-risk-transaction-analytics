import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface Summary {
  transactions: number;
  customers: number;
  avg_risk_score: string;
  high_risk_accounts: number;
  avg_utilization: string;
}

export interface HighRiskAccount {
  account_id: number;
  customer_id: number;
  state: string;
  credit_score: number;
  utilization: string;
  late_or_missed_payments: number;
  avg_days_late: string;
  risk_score: string;
  risk_rank: number;
}

@Injectable({ providedIn: 'root' })
export class ApiService {
  private readonly baseUrl = 'http://localhost:3000/api/dashboard';

  constructor(private http: HttpClient) {}

  getSummary(): Observable<Summary> {
    return this.http.get<Summary>(`${this.baseUrl}/summary`);
  }

  getHighRiskAccounts(limit = 15): Observable<HighRiskAccount[]> {
    return this.http.get<HighRiskAccount[]>(
      `${this.baseUrl}/high-risk-accounts?limit=${limit}`
    );
  }

  getRiskDistribution(): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/risk-distribution`);
  }

  getMonthlyTrends(): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/monthly-trends`);
  }

  getCohorts(): Observable<any[]> {
    return this.http.get<any[]>(`${this.baseUrl}/cohorts`);
  }
}
