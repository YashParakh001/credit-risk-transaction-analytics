import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ApiService, HighRiskAccount, Summary } from './api.service';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent implements OnInit {
  summary?: Summary;
  highRiskAccounts: HighRiskAccount[] = [];
  riskDistribution: any[] = [];
  loading = true;
  error = '';

  constructor(private api: ApiService) {}

  ngOnInit(): void {
    this.api.getSummary().subscribe({
      next: data => {
        this.summary = data;
        this.loading = false;
      },
      error: () => {
        this.error = 'Could not load dashboard data.';
        this.loading = false;
      }
    });

    this.api.getHighRiskAccounts(15)
      .subscribe(data => this.highRiskAccounts = data);

    this.api.getRiskDistribution()
      .subscribe(data => this.riskDistribution = data);
  }

  pct(value: string | number): string {
    return `${(Number(value) * 100).toFixed(1)}%`;
  }
}
